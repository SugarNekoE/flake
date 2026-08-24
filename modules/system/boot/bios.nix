{
  flake.modules.nixos.bios = {
    boot.loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        efiSupport = false;
      };
    };
  };
}
