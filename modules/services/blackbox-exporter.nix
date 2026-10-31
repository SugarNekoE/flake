_: {
  nixos =
    { pkgs, ... }:
    {
      services.prometheus.exporters.blackbox = {
        enable = true;
        listenAddress = "127.0.0.1";
        configFile = (pkgs.formats.yaml { }).generate "blackbox.yaml" {
          modules = {
            http_2xx = {
              prober = "http";
              timeout = "10s";
              http.preferred_ip_protocol = "ip4";
            };
            tcp_connect = {
              prober = "tcp";
              timeout = "5s";
            };
            icmp = {
              prober = "icmp";
              timeout = "5s";
            };
          };
        };
      };
    };
}
