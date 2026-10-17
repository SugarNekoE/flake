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
    (sing-box.withProfile {
      sopsFile = ../secrets/sing-box/home.json;
    })
    (stylix.withWallpaper {
      url = "https://assets.sne.moe/Backgrounds/StarNightGirl.jpg";
      hash = "sha256-M4gQnXnNA7tJzSpf0tFWOyHCjablUXQWWAhdDdApHAA=";
    })
    (netbird.withSetupKey {
      sopsFile = ../secrets/netbird/atme.yaml;
      managementUrl = "https://connect.techinteaching.cn:443";
      name = "atme";
      port = 51820;
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
      inputs,
      identity,
      user,
      lib,
      ...
    }:
    {
      imports = [ inputs.paseo.nixosModules.default ];
      users.users.${user.username}.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];
      networking.firewall.enable = false;
      services = {
        openssh.settings.AllowAgentForwarding = true;
        paseo-daemon = {
          enable = true;
          user = "${user.username}";
          dataDir = "/home/${user.username}/.paseo";
          listenAddress = "0.0.0.0";
          openFirewall = true;
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

      boot.initrd.availableKernelModules = [ "nvme" ];
      boot.initrd.kernelModules = [ "dm-snapshot" ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/nvme0n1";

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
