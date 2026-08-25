{
  nixos = {
    boot.loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        efiSupport = false;
      };
    };
  };
}
