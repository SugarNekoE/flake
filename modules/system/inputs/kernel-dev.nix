{ inputs, ... }:
{
  flake-file.inputs.kernel-dev = {
    url = "git+https://forge.asnk.io/sugar/kernel-dev";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.kernelDev;
      kernelModule = lib.evalModules {
        specialArgs = { inherit pkgs; };
        modules = [
          inputs.kernel-dev.nixosModules.default
          {
            options.boot.kernelPackages = lib.mkOption {
              type = lib.types.nullOr lib.types.raw;
              default = null;
            };
          }
        ];
      };
      kernelPackages = kernelModule.config.boot.kernelPackages;
    in
    {
      options.kernelDev.enable = lib.mkEnableOption "the locally developed Linux kernel when its source is available";

      config = lib.mkIf (cfg.enable && kernelPackages != null) {
        boot.kernelPackages = lib.mkForce kernelPackages;
      };
    };
}
