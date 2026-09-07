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

      networking.firewall = {
        allowPing = true;
        allowedTCPPorts = [
          22
          2080
          9990
        ];
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
