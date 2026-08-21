{
  config,
  inputs,
  lib,
  ...
}:
let
  aspectType = {
    options = {
      nixosModule = lib.mkOption {
        type = lib.types.nullOr lib.types.deferredModule;
        default = null;
        description = "NixOS module contributed by this aspect.";
      };

      homeModule = lib.mkOption {
        type = lib.types.nullOr lib.types.deferredModule;
        default = null;
        description = "Home Manager module contributed by this aspect.";
      };
    };
  };

  machineType = {
    options = {
      system = lib.mkOption {
        type = lib.types.str;
        description = "Nix system used by this machine.";
      };

      diskoConfig = lib.mkOption {
        type = lib.types.nullOr lib.types.deferredModule;
        default = null;
        description = "Optional disko layout for this machine.";
      };

      hardware = lib.mkOption {
        type = lib.types.nullOr lib.types.deferredModule;
        default = null;
        description = "Hardware module for this machine.";
      };
    };
  };

  moduleNames = lib.unique (
    builtins.attrNames config.flake.modules.nixos ++ builtins.attrNames config.flake.modules.homeManager
  );

  inferredAspects = lib.genAttrs moduleNames (name: {
    config =
      lib.optionalAttrs (builtins.hasAttr name config.flake.modules.nixos) {
        nixosModule = config.flake.modules.nixos.${name};
      }
      // lib.optionalAttrs (builtins.hasAttr name config.flake.modules.homeManager) {
        homeModule = config.flake.modules.homeManager.${name};
      };
  });

  buildMachine =
    _name: machine:
    inputs.nixpkgs.lib.nixosSystem {
      inherit (machine) system;
      modules =
        lib.optional (machine.nixosModule != null) machine.nixosModule
        ++ lib.optional (machine.diskoConfig != null) machine.diskoConfig
        ++ lib.optional (machine.hardware != null) machine.hardware
        ++ lib.optional (machine.homeModule != null) {
          home-manager.sharedModules = [ machine.homeModule ];
        };
    };
in
{
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
    flake.nixosConfigurations = lib.mapAttrs buildMachine config.machines;
  };
}
