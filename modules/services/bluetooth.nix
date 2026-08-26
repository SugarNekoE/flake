_: {
  nixos = {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };

  home = {
    services.blueman-applet.enable = true;
  };
}
