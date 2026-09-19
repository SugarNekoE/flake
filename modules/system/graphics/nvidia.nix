{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      kernel = config.boot.kernelPackages.kernel;
      driver = (pkgs.unstable.linuxPackagesFor kernel).nvidiaPackages.latest;
      openDriver = driver.open.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          if grep -q 'struct dmem_cgroup_init {' \
            ${kernel.dev}/lib/modules/${kernel.modDirVersion}/source/include/linux/cgroup_dmem.h; then
            substituteInPlace kernel-open/nvidia/os-interface.c \
              --replace-fail 'dmem_cgroup_register_region(size, name)' \
                'dmem_cgroup_register_region(&(struct dmem_cgroup_init){ .size = size }, "%s", name)'
          fi
        '';
      });
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
          package =
            driver
            // lib.optionalAttrs (driver.version == "610.57.04") {
              open = openDriver;
            };
        };
      };
      services.xserver.videoDrivers = [ "nvidia" ];
      boot.kernelParams = [
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
        "nvidia.NVreg_TemporaryFilePath=/var/tmp"
      ];
    };
}
