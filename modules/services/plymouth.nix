_: {
  nixos = {
    boot = {
      plymouth = {
        enable = true;
        theme = "bgrt";
      };
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "udev.log_level=3"
        "rd.udev.log_level=3"
      ];
    };
  };
}
