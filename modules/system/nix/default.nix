{ inputs, ... }:
{
  nixos =
    { pkgs, options, ... }:
    {
      nix = {
        package = pkgs.nix;
        channel.enable = false;

        registry.sugar.flake = inputs.self;

        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          extra-substituters = [
            "https://nix-community.cachix.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          trusted-users = [ "@wheel" ];
        };

        nixPath = [ "/etc/nix/path" ];

        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 7d";
        };
      };

      boot.kernelPackages = pkgs.linuxKernel.packages.linux_7_2;
      boot.loader.systemd-boot.configurationLimit = 10;
      boot.supportedFilesystems = [
        "btrfs"
        "exfat"
        "ext4"
        "f2fs"
        "ntfs"
        "vfat"
        "xfs"
      ];

      nixpkgs.config.allowUnfree = true;

      networking.nftables.enable = true;
      networking.timeServers = options.networking.timeServers.default ++ [
        "ntp.aliyun.com"
        "ntp.ntsc.ac.cn"
        "time.apple.com"
      ];

      services.resolved.enable = true;

      environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
    };
}
