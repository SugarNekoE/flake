_: {
  nixos = {
    services.printing = {
      enable = true;
      cups-pdf.enable = false;
      openFirewall = true;
    };
  };
}
