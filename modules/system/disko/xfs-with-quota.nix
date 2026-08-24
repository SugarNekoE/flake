{
  flake.diskoConfigurations.xfs-with-quota = {
    disko.devices.disk.system = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
              mountOptions = [ "umask=0077" ];
            };
          };
          boot = {
            size = "2G";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = "/";
              mountOptions = [
                "defaults"
                "pquota"
              ];
            };
          };
        };
      };
    };
  };
}
