{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n

    # roles
    base
    server

    # services
    (sing-box.withProfile {
      sopsFile = ../secrets/sing-box/home.json;
    })
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    {
      identity,
      pkgs,
      lib,
      ...
    }:
    {
      nix.settings.substituters = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];

      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.singcat ];

      networking.firewall.enable = lib.mkForce false;

      environment.etc."containers/registries.conf".source = lib.mkForce (
        pkgs.writeText "registries.conf" ''
          unqualified-search-registries = ["docker.io"]

          [[registry]]
          prefix = "docker.io"
          location = "docker.io"

          [[registry.mirror]]
          location = "docker.1ms.run"

          [[registry.mirror]]
          location = "docker.m.daocloud.io"

          [[registry.mirror]]
          location = "dockerproxy.net"
        ''
      );

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
  hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:

    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
      ];

      disko.devices.disk.system.device = "/dev/vda";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    };
}
