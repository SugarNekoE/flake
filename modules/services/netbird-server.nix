let
  installPath = "/opt/netbird";
in
{
  nixos = {
    services.traefik = {
      enable = true;

      staticConfigOptions = {
        log.level = "INFO";
        accessLog = { };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
          };
          websecure = {
            address = ":443";
            transport.respondingTimeouts = {
              readTimeout = "0s";
              writeTimeout = "0s";
              idleTimeout = "0s";
            };
          };
        };

        certificatesResolvers.letsencrypt.acme = {
          email = "sugar@sne.moe";
          storage = "${installPath}/data/netbird_traefik_letsencrypt/acme.json";
          tlsChallenge = { };
        };
      };

      dynamicConfigOptions = {
        http = {
          routers = {
            dashboard = {
              rule = "Host(`connect.sne.moe`)";
              entryPoints = [ "websecure" ];
              tls.certResolver = "letsencrypt";
              service = "dashboard";
            };

            netbird-grpc = {
              rule = "Host(`connect.sne.moe`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`) || PathPrefix(`/management.ProxyService/`))";
              entryPoints = [ "websecure" ];
              tls.certResolver = "letsencrypt";
              service = "netbird-h2c";
            };

            netbird-backend = {
              rule = "Host(`connect.sne.moe`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))";
              entryPoints = [ "websecure" ];
              tls.certResolver = "letsencrypt";
              service = "netbird";
            };
          };

          services = {
            dashboard.loadBalancer.servers = [
              { url = "http://127.0.0.1:8080"; }
            ];

            netbird.loadBalancer.servers = [
              { url = "http://127.0.0.1:8081"; }
            ];

            netbird-h2c.loadBalancer.servers = [
              { url = "h2c://127.0.0.1:8081"; }
            ];
          };
        };

        tcp = {
          routers.proxy-passthrough = {
            rule = "HostSNI(`*`) && !HostSNI(`connect.sne.moe`)";
            entryPoints = [ "websecure" ];
            priority = 1;
            tls.passthrough = true;
            service = "proxy-tls";
          };

          services.proxy-tls.loadBalancer = {
            servers = [
              { address = "127.0.0.1:8443"; }
            ];
            serversTransport = "pp-v2";
          };

          serversTransports.pp-v2.proxyProtocol.version = 2;
        };
      };
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        netbird-dashboard = {
          image = "docker.io/netbirdio/dashboard:latest";
          ports = [
            "127.0.0.1:8080:80"
          ];
          environmentFiles = [
            "${installPath}/dashboard.env"
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
          ];
        };

        netbird-server = {
          image = "docker.io/netbirdio/netbird-server:latest";
          ports = [
            "127.0.0.1:8081:80"
          ];
          cmd = [
            "--config"
            "/etc/netbird/config.yaml"
          ];
          volumes = [
            "${installPath}/data/netbird_data:/var/lib/netbird"
            "${installPath}/config.yaml:/etc/netbird/config.yaml:ro"
          ];
        };

        netbird-proxy = {
          image = "docker.io/netbirdio/reverse-proxy:latest";
          ports = [
            "127.0.0.1:8443:8443"
            "51820:51820/udp"
          ];
          environmentFiles = [
            "${installPath}/proxy.env"
          ];
          environment = {
            NB_PROXY_PROXY_PROTOCOL = "true";
            NB_PROXY_TRUSTED_PROXIES = "10.88.0.0/16";
          };
          volumes = [
            "${installPath}/data/netbird_proxy_certs:/certs"
          ];
          dependsOn = [
            "netbird-server"
          ];
        };

        crowdsec = {
          image = "docker.io/crowdsecurity/crowdsec:v1.7.7";
          environment = {
            COLLECTIONS = "crowdsecurity/linux";
          };
          volumes = [
            "${installPath}/crowdsec:/etc/crowdsec"
            "${installPath}/data/crowdsec_db:/var/lib/crowdsec/data"
          ];
        };
      };
    };

    systemd.tmpfiles.rules = [
      "d ${installPath} 0751 root root -"
      "d ${installPath}/crowdsec 0750 root root -"
      "d ${installPath}/data 0751 root root -"
      "d ${installPath}/data/netbird_data 0750 root root -"
      "d ${installPath}/data/netbird_traefik_letsencrypt 0700 traefik traefik -"
      "d ${installPath}/data/netbird_proxy_certs 0700 1000 1000 -"
      "d ${installPath}/data/crowdsec_db 0750 root root -"
    ];
  };
}
