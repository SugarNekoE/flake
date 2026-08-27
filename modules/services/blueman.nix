_: {
  nixos = {
    services.blueman.enable = true;
  };
  home = {
    services.blueman-applet.enable = true;
  };
}
