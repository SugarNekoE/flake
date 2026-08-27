_: {
  nixos = {
    services.fprintd.enable = true;
    security.pam.services.swaylock.fprintAuth = true;
  };
}
