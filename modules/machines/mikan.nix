{ config, inputs, ... }:
{
  user = config.userProfiles.sugar;
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    sugar

    # system
    efi
    i18n

    # services
    podman
    networkmanager
    (singbox-gui.withProfile {
      name = "SNEPX";
      sopsFile = ../secrets/sing-box/home.json;
    })
    (stylix.withWallpaper {
      url = "https://assets.sne.moe/Backgrounds/StarNightGirl.jpg";
      hash = "sha256-M4gQnXnNA7tJzSpf0tFWOyHCjablUXQWWAhdDdApHAA=";
    })

    # roles
    base
    agents

    # apps
    git
    fish
    kitty
    gnupg
    neovim
    starship
    unix-tools
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    {
      identity,
      user,
      lib,
      ...
    }:
    {
      users.users.${user.username}.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];
      networking.firewall.enable = false;
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

      boot.initrd.availableKernelModules = [ "nvme" ];
      boot.initrd.kernelModules = [ "dm-snapshot" ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/nvme0n1";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
