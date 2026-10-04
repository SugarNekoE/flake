{
  config,
  inputs,
  lib,
  ...
}:
let
  adapterFile = toString ./aspects.nix;
  moduleRoot = toString ./.;
  normalizeModuleName = name: if builtins.match "^[0-9].*" name != null then "_${name}" else name;
  moduleName =
    file:
    let
      path = toString file;
      fileName = lib.removeSuffix ".nix" (baseNameOf path);
      name = if fileName == "default" then baseNameOf (dirOf path) else fileName;
    in
    normalizeModuleName name;
  moduleRelativePath = file: lib.removePrefix "${moduleRoot}/" (toString file);
  moduleKind =
    file:
    let
      relativePath = moduleRelativePath file;
    in
    if lib.hasPrefix "roles/" relativePath then
      "role"
    else if lib.hasPrefix "machines/" relativePath then
      "machine"
    else
      "module";
  moduleFiles = builtins.filter (file: toString file != adapterFile) (inputs.import-tree.leaves ./.);
  machineModuleFiles = builtins.filter (file: moduleKind file == "machine") moduleFiles;
  aspectModuleFiles = builtins.filter (file: moduleKind file != "machine") moduleFiles;
  duplicateNames =
    files:
    let
      grouped = builtins.groupBy moduleName files;
    in
    lib.attrNames (lib.filterAttrs (_name: group: builtins.length group > 1) grouped);
  duplicateMachineNames = duplicateNames machineModuleFiles;
  duplicateAspectNames = duplicateNames aspectModuleFiles;

  adaptModule =
    file: moduleArgs:
    let
      name = moduleName file;
      source = import file;
      definition = if builtins.isFunction source then source moduleArgs else source;
      passthrough = removeAttrs definition [
        "darwin"
        "home"
        "nixos"
      ];
    in
    if !builtins.isAttrs definition then
      throw "module `${name}` must return a flake-parts module attribute set"
    else if moduleKind file == "machine" then
      {
        _file = toString file;
        config.machines.${name} =
          passthrough
          // lib.optionalAttrs ((definition.nixos or null) != null) {
            nixosModule = definition.nixos;
          }
          // lib.optionalAttrs ((definition.darwin or null) != null) {
            darwinModule = definition.darwin;
          }
          // lib.optionalAttrs ((definition.home or null) != null) {
            homeModule = definition.home;
          };
      }
    else if moduleKind file == "role" then
      {
        _file = toString file;
        config.flake.modules.aspects.${name} = {
          imports = [ passthrough ];
          config = lib.filterAttrs (_field: module: module != null) {
            nixosModule = definition.nixos or null;
            darwinModule = definition.darwin or null;
            homeModule = definition.home or null;
          };
        };
      }
    else
      {
        _file = toString file;
        imports = [
          passthrough
        ]
        ++ lib.optional ((definition.nixos or null) != null) {
          flake.modules.nixos.${name} = definition.nixos;
        }
        ++ lib.optional ((definition.darwin or null) != null) {
          flake.modules.darwin.${name} = definition.darwin;
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
      darwinModule = nullableModule "nix-darwin module contributed by this aspect.";
      homeModule = nullableModule "Home Manager module contributed by this aspect.";
      home = nullableModule "Selector that keeps only this aspect's Home Manager module.";
      nixos = nullableModule "Selector that keeps only this aspect's NixOS module.";
      darwin = nullableModule "Selector that keeps only this aspect's nix-darwin module.";
    };
  };

  machineType = {
    options = {
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.attrs;
        default = null;
        description = "Selected user profile passed to system and Home Manager modules.";
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
    builtins.attrNames config.flake.modules.nixos
    ++ builtins.attrNames config.flake.modules.darwin
    ++ builtins.attrNames config.flake.modules.homeManager
  );

  inferredAspects = lib.genAttrs moduleNames (name: {
    config = lib.filterAttrs (_field: module: module != null) {
      nixosModule = config.flake.modules.nixos.${name} or null;
      darwinModule = config.flake.modules.darwin.${name} or null;
      homeModule = config.flake.modules.homeManager.${name} or null;
    };
  });

  selectAspect =
    name: aspect:
    let
      module = builtins.head (aspect { }).imports;
      parsed =
        if module ? imports then
          (lib.evalModules {
            class = "aspects";
            specialArgs = { inherit inputs; };
            modules = [
              aspectType
              module
            ];
          }).config
        else
          module.config or { };
      nixosModule = parsed.nixosModule or null;
      darwinModule = parsed.darwinModule or null;
      homeModule = parsed.homeModule or null;
      modules = lib.filterAttrs (_field: module: module != null) {
        inherit nixosModule darwinModule homeModule;
      };
      modulePayload = {
        _class = "aspects";
      }
      // modules;
      homeOnly = {
        _class = "aspects";
      }
      // lib.optionalAttrs (homeModule != null) {
        inherit homeModule;
      };
      nixosOnly = {
        _class = "aspects";
      }
      // lib.optionalAttrs (nixosModule != null) {
        inherit nixosModule;
      };
      darwinOnly = {
        _class = "aspects";
      }
      // lib.optionalAttrs (darwinModule != null) {
        inherit darwinModule;
      };
      helpers = config.aspectHelpers.${name} or { };
    in
    modulePayload
    // {
      home = homeOnly;
      nixos = nixosOnly;
      darwin = darwinOnly;
      __functor = _self: _args: modulePayload;
    }
    // helpers;

  selectableAspects = lib.mapAttrs selectAspect config.flake.modules.aspects;

  machineArgs =
    machine:
    {
      inherit inputs;
      inherit (config) identity;
    }
    // lib.optionalAttrs (machine.user != null) {
      inherit (machine) user;
    };

  buildMachine =
    name: machine:
    let
      sharedArgs = machineArgs machine;
      machineModules = [
        { networking.hostName = name; }
      ]
      ++ lib.optional (machine.nixosModule != null) machine.nixosModule
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

  buildDarwinMachine =
    name: machine:
    let
      sharedArgs = machineArgs machine;
      machineModules = [
        {
          networking.hostName = name;
          nixpkgs.hostPlatform = machine.system;
        }
      ]
      ++ lib.optional (machine.darwinModule != null) machine.darwinModule
      ++ lib.optionals (machine.homeModule != null) [
        inputs.home-manager.darwinModules.home-manager
        {
          home-manager = {
            extraSpecialArgs = sharedArgs;
            sharedModules = [ machine.homeModule ];
          };
        }
      ];
    in
    if machine.hardware != null || machine.diskoConfig != null then
      throw "Darwin machine `${name}` cannot declare NixOS hardware or disko modules"
    else
      inputs.nix-darwin.lib.darwinSystem {
        specialArgs = sharedArgs;
        modules = machineModules;
      };

  darwinMachines = lib.filterAttrs (
    _name: machine: lib.hasSuffix "-darwin" machine.system
  ) config.machines;
  nixosMachines = lib.filterAttrs (
    _name: machine: !lib.hasSuffix "-darwin" machine.system
  ) config.machines;

  validatedModuleFiles =
    if duplicateAspectNames != [ ] then
      throw "duplicate aspect module names are not allowed: ${lib.concatStringsSep ", " duplicateAspectNames}"
    else if duplicateMachineNames != [ ] then
      throw "duplicate machine names are not allowed: ${lib.concatStringsSep ", " duplicateMachineNames}"
    else
      moduleFiles;
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
    description = "Machines materialized as NixOS or nix-darwin configurations.";
  };

  options.aspectHelpers = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.attrsOf lib.types.raw);
    default = { };
    internal = true;
    description = "Helpers attached to selectable aspects without participating in module merges.";
  };

  config = {
    flake.modules.generic.aspect-interface = aspectType;
    flake.modules.aspects = inferredAspects;
    flake.aspects = selectableAspects;
    flake.nixosConfigurations = lib.mapAttrs buildMachine nixosMachines;
    flake.darwinConfigurations = lib.mapAttrs buildDarwinMachine darwinMachines;
  };
}
