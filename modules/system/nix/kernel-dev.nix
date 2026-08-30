{ inputs, ... }:
{
  flake-file.inputs.kernel-dev = {
    url = "git+file:///mnt/data/Projects/kernel-dev";
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
      kernelModule = inputs.kernel-dev.nixosModules.default { inherit pkgs; };
    in
    {
      options.kernelDev.enable = lib.mkEnableOption "the locally developed Linux kernel";

      config = lib.mkIf cfg.enable {
        boot.kernelPackages = lib.mkForce kernelModule.boot.kernelPackages;
      };
    };
}
