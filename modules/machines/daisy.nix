{ config, inputs, ... }:
{
  user = config.userProfiles.sugar;
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    sugar

    # system
    efi
    igpu
    i18n

    # services
    audio
    bluetooth
    fonts
    netbird
    networkmanager
    podman
    power
    plymouth
    polkit
    (openssh.withKnownHosts { })
    (singbox-gui.withProfile {
      name = "SNEPX";
      sopsFile = ../secrets/sing-box/remote.json;
    })
    (stylix.withWallpaper {
      url = "https://assets.sne.moe/Backgrounds/Frieren.jpg";
      hash = "sha256-/W5n8M8vVqwr0bQPJK+mVCzBzpQk9AcBdb8iPyWszPY=";
    })

    # roles
    base
    desktop
    laptop
    develop
    office
    social
    unixkey
    work

    # apps
    sway
    waybar
    ly
    sdrpp
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-luks;
  homeModule = {
    wayland.windowManager.sway.config.output = {
      "eDP-1" = {
        mode = "1920x1200@60Hz";
        scale = "1.25";
      };
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
        "thunderbolt"
        "nvme"
        "usbhid"
      ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/nvme0n1";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
