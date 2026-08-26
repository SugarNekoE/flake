let
  luksPasswordFile = "/tmp/disko-luks-password";
in
{
  flake.diskoConfigurations.xfs-with-luks = {
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
            type = "8309";
            size = "100%";
            content = {
              type = "luks";
              name = "crypted-root";
              passwordFile = luksPasswordFile;
              settings.allowDiscards = false;
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
  };
}
