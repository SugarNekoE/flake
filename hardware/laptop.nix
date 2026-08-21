{ lib, ... }:
{
  # Evaluation-only placeholders. Replace this file with the generated hardware
  # configuration and an actual boot/filesystem layout before installing.
  boot.loader.grub.devices = [ "nodev" ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  networking.hostName = "laptop";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
