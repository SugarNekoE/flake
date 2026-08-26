_: {
  home.wayland.windowManager.sway.config.input."type:touchpad".natural_scroll = "disabled";

  nixos = {
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "lock";
      HandleLidSwitchDocked = "lock";
    };

    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "30min";
      HibernateOnACPower = false;
    };

    swapDevices = [
      {
        device = "/var/lib/swapfile";
        size = 32 * 1024;
      }
    ];
  };
}
