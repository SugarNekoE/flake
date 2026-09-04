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
    podman
    uptimekuma
    (sing-box.withProfile {
      sopsFile = ../secrets/sing-box/home.json;
    })
    (netbird.withSetupKey {
      sopsFile = ../secrets/netbird/sne-connect.yaml;
      managementUrl = "https://connect.sne.moe:443";
      name = "sne-connect";
      port = 51820;
    })
    (cloudflared.withSecret ../secrets/cloudflared/aster.yaml)
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

      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.aster ];

      networking.firewall = {
        allowPing = true;
        allowedTCPPorts = [
          22
          9990
        ];
      };

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

      system.autoUpgrade = {
        enable = true;
        upgrade = true;
        operation = "switch";
        flake = "git+https://forge.asnk.io/sugar/flake";
        dates = "4:00";
        flags = [
          "--refresh"
        ];
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
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "xhci_pci"
        "ahci"
        "ehci_pci"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/sda";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
