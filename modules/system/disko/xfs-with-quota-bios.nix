{
  flake.diskoConfigurations.xfs-with-quota-bios = {
    disko.devices.disk.system = {
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          bios = {
            type = "EF02";
            size = "1G";
          };
          boot = {
            size = "2G";
            content = {
              type = "filesystem";
              format = "ext4";
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
