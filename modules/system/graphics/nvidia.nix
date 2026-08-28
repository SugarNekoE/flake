{
  nixos =
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
          package = (pkgs.unstable.linuxPackagesFor config.boot.kernelPackages.kernel).nvidiaPackages.latest;
        };
      };
      services.xserver.videoDrivers = [ "nvidia" ];
    };
}
