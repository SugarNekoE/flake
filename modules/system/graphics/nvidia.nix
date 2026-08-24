{
  flake.modules.nixos.nvidia =
    { config, pkgs, ... }:
    {
      hardware = {
        graphics = {
          enable = true;
          extraPackages = with pkgs; [
            nvidia-vaapi-driver
          ];
        };
        nvidia = {
          open = true;
          modesetting.enable = true;
          powerManagement.enable = true;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.beta;
        };
      };
      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
