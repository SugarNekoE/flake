{
  config,
  inputs,
  lib,
  ...
}:
let
  adapterFile = toString ./aspects.nix;
  moduleName =
    file:
    let
      path = toString file;
      name = lib.removeSuffix ".nix" (baseNameOf path);
    in
    if name == "default" then baseNameOf (dirOf path) else name;
  moduleFiles = builtins.filter (file: toString file != adapterFile) (inputs.import-tree.leafs ./.);
  sourceModuleNames = map moduleName moduleFiles;
  duplicateSourceNames = lib.filter (
    name: builtins.length (lib.filter (candidate: candidate == name) sourceModuleNames) > 1
  ) (lib.unique sourceModuleNames);

  adaptModule =
    file: moduleArgs:
    let
      name = moduleName file;
      source = import file;
      definition = if builtins.isFunction source then source moduleArgs else source;
      passthrough = removeAttrs definition [
        "home"
        "nixos"
      ];
    in
    if !builtins.isAttrs definition then
      throw "module `${name}` must return a flake-parts module attribute set"
    else
      {
        _file = toString file;
        imports = [
          passthrough
        ]
        ++ lib.optional ((definition.nixos or null) != null) {
          flake.modules.nixos.${name} = definition.nixos;
        }
        ++ lib.optional ((definition.home or null) != null) {
          flake.modules.homeManager.${name} = definition.home;
        };
      };

  nullableModule =
    description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.deferredModule;
      default = null;
      inherit description;
    };

  aspectType = {
    options = {
      nixosModule = nullableModule "NixOS module contributed by this aspect.";
      homeModule = nullableModule "Home Manager module contributed by this aspect.";
      home = nullableModule "Selector that keeps only this aspect's Home Manager module.";
      nixos = nullableModule "Selector that keeps only this aspect's NixOS module.";
    };
  };

  machineType = {
    options = {
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
        description = "Selected user profile passed to NixOS and Home Manager modules.";
      };

      system = lib.mkOption {
        type = lib.types.str;
        description = "Nix system used by this machine.";
      };

      diskoConfig = nullableModule "Optional disko layout for this machine.";
      hardware = nullableModule "Hardware module for this machine.";
    };
  };

  moduleNames = lib.unique (
    builtins.attrNames config.flake.modules.nixos ++ builtins.attrNames config.flake.modules.homeManager
  );

  inferredAspects = lib.genAttrs moduleNames (name: {
    config = lib.filterAttrs (_field: module: module != null) {
      nixosModule = config.flake.modules.nixos.${name} or null;
      homeModule = config.flake.modules.homeManager.${name} or null;
    };
  });

  selectAspect =
    aspect:
    let
      parsed =
        (lib.evalModules {
          class = "aspects";
          modules = [
            aspectType
            aspect
          ];
        }).config;
      modules = lib.filterAttrs (_field: module: module != null) {
        nixosModule = parsed.nixosModule;
        homeModule = parsed.homeModule;
      };
      homeOnly = {
        _class = "aspects";
      }
      // lib.optionalAttrs (parsed.homeModule != null) {
        homeModule = parsed.homeModule;
      };
      nixosOnly = {
        _class = "aspects";
      }
      // lib.optionalAttrs (parsed.nixosModule != null) {
        nixosModule = parsed.nixosModule;
      };
    in
    {
      _class = "aspects";
      home = homeOnly;
      nixos = nixosOnly;
    }
    // modules;

  selectableAspects = lib.mapAttrs (_name: selectAspect) config.flake.modules.aspects;

  buildMachine =
    _name: machine:
    let
      sharedArgs = {
        inherit inputs;
        identity = config.identity;
      }
      // lib.optionalAttrs (machine.user != null) {
        user = machine.user;
      };
      machineModules =
        lib.optional (machine.nixosModule != null) machine.nixosModule
        ++ lib.optional (machine.hardware != null) machine.hardware
        ++ lib.optionals (machine.diskoConfig != null) [
          inputs.disko.nixosModules.disko
          machine.diskoConfig
        ]
        ++ lib.optionals (machine.homeModule != null) [
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = sharedArgs;
              sharedModules = [ machine.homeModule ];
            };
          }
        ];
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit (machine) system;
      specialArgs = sharedArgs;
      modules = machineModules;
    };
  validatedModuleFiles =
    if duplicateSourceNames == [ ] then
      moduleFiles
    else
      throw "duplicate aspect module names are not allowed: ${lib.concatStringsSep ", " duplicateSourceNames}";
in
{
  imports = map adaptModule validatedModuleFiles;

  options.machines = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        class = "aspects";
        modules = [
          aspectType
          machineType
        ];
      }
    );
    default = { };
    description = "Machines materialized as NixOS configurations.";
  };

  config = {
    flake.modules.generic.aspect-interface = aspectType;
    flake.modules.aspects = inferredAspects;
    flake.aspects = selectableAspects;
    flake.nixosConfigurations = lib.mapAttrs buildMachine config.machines;
  };
}
