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
    (sing-box.withProfile {
      sopsFile = ../secrets/sing-box/home.json;
    })
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    {
      identity,
      ...
    }:
    {
      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.aster ];
      networking.firewall = {
        allowPing = true;
        allowedTCPPorts = [ 22 ];
      };
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
      nixpkgs,
      config,
      lib,
      pkgs,
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
