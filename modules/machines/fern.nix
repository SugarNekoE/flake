{ config, inputs, ... }:
{
  user = config.userProfiles.sugar;
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    sugar

    # system
    efi
    nvidia
    i18n
    xfs
    (cifs.withCredentials {
      sopsFile = ../secrets/cifs/home-cifs.yaml;
    })

    # services
    audio
    bluetooth
    fonts
    networkmanager.nixos
    podman
    power
    plymouth
    polkit.nixos
    (openssh.withKnownHosts {
      fern = {
        hostNames = [ "fern" ];
        publicKey = config.identity.sshKeys.fern;
      };
    })
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
    desktop
    develop
    games
    office
    social
    work

    # apps
    plasma
    logitech
    sdrpp
    davinci
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    { identity, user, ... }:
    {
      users.users.${user.username}.openssh.authorizedKeys.keys = [ identity.sshKeys.daisy ];
      networking.firewall.enable = false;
    };
  hardware =
    {
      config,
      lib,
      modulesPath,
      ...
    }:
    let
      cifsCredentialsFile =
        config.sops.secrets."cifs-credentials".path or "/run/secrets/cifs-credentials";
    in
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
      ];

      boot.initrd.availableKernelModules = [
        "nvme"
        "ahci"
        "sd_mod"
      ];
      boot.initrd.kernelModules = [ "dm-snapshot" ];
      boot.kernelModules = [ "kvm-amd" ];
      boot.extraModulePackages = [ ];

      disko.devices.disk.system.device = "/dev/disk/by-id/nvme-ZHITAI_TiPlus5000_1TB_ZTA21T0KA2342203FY";

      mounts.xfs = {
        "/mnt/data" = {
          device = "/dev/disk/by-uuid/86ac1715-d3f0-43b4-824f-9c83f8e3e3b2";
        };
        "/mnt/meta" = {
          device = "/dev/disk/by-uuid/017bcde8-d534-47e8-b848-f7f70d96b6d2";
        };
      };

      mounts.cifs = {
        "/mnt/sugar-storage" = {
          remote = "//10.0.0.23/sugar";
          credentialsFile = cifsCredentialsFile;
          extraOptions = [
            "uid=1000"
            "gid=100"
          ];
        };
        "/mnt/nixcn-media" = {
          remote = "//10.0.0.23/nixcn-media";
          credentialsFile = cifsCredentialsFile;
          extraOptions = [
            "uid=1000"
            "gid=100"
          ];
        };
        "/mnt/jellyfin" = {
          remote = "//10.0.0.23/jellyfin";
          credentialsFile = cifsCredentialsFile;
          extraOptions = [
            "uid=1000"
            "gid=100"
          ];
        };
        "/mnt/ignis-network" = {
          remote = "//10.0.0.23/ignis-network";
          credentialsFile = cifsCredentialsFile;
          extraOptions = [
            "uid=1000"
            "gid=100"
          ];
        };
        "/mnt/lolihoust" = {
          remote = "//10.0.0.23/lolihoust";
          credentialsFile = cifsCredentialsFile;
          extraOptions = [
            "uid=1000"
            "gid=100"
          ];
        };
      };

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
