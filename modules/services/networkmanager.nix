_: {
  nixos = {
    networking.networkmanager.enable = true;
  };

  home = {
    services.network-manager-applet.enable = true;
  };
}
