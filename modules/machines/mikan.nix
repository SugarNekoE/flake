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
      ...
    }:
    {
      imports = [ inputs.paseo.nixosModules.default ];
      users.users.${user.username}.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];
      networking.firewall.enable = false;
      services = {
        paseo-daemon = {
          enable = true;
          user = "${user.username}";
          dataDir = "/home/${user.username}/.paseo";
          listenAddress = "0.0.0.0";
          openFirewall = true;
        };
      };
      sops.secrets.mikan-ssh-key = {
        sopsFile = ../secrets/mikan-ssh-key.yaml;
        key = "private-key";
        owner = user.username;
        mode = "0400";
      };
    };
  home =
    { lib, nixosConfig, ... }:
    {
      services.gpg-agent = {
        defaultCacheTtl = lib.mkForce 86400;
        maxCacheTtl = lib.mkForce 2592000;
      };
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*" = {
          IdentityFile = nixosConfig.sops.secrets.mikan-ssh-key.path;
          IdentitiesOnly = true;
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
