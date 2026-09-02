{ config, lib, ... }:
let
  qcow2Module =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    {
      imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

      disko = {
        devices.disk.system = {
          device = lib.mkForce "/dev/vda";
          imageName = lib.mkForce config.networking.hostName;
          imageSize = lib.mkDefault "32G";
        };
        imageBuilder.imageFormat = "qcow2";
      };

      services = {
        cloud-init = {
          enable = true;
          network.enable = true;
          settings = {
            preserve_hostname = false;
            growpart = {
              mode = "auto";
              devices = [ "/" ];
            };
            resize_rootfs = true;
          };
        };
        qemuGuest.enable = true;
      };
    };

  buildQcow2 = nixosConfiguration: nixosConfiguration.extendModules { modules = [ qcow2Module ]; };
in
{
  flake = {
    lib.buildQcow2 = buildQcow2;
    qcow2Configurations = lib.mapAttrs (_: buildQcow2) config.flake.nixosConfigurations;
  };
}
