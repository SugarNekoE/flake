{
  nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      kernel = config.boot.kernelPackages.kernel;
      driver = (pkgs.unstable.linuxPackagesFor kernel).nvidiaPackages.latest;
    in
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
          package = driver;
        };
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      boot.kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      ];
    };
}
