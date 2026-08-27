_: {
  nixos = {
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
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
