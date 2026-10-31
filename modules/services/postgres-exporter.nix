_: {
  nixos = {
    services.prometheus.exporters.postgres = {
      enable = true;
      listenAddress = "127.0.0.1";
    };
  };
}
