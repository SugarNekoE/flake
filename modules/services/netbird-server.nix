let
  installPath = "/opt/netbird";
  traefikIP = "172.30.0.10";
in
{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      domain = "connect.sne.moe";
      acmeEmail = "sugar@sne.moe";
      containerNames = [
        "netbird-traefik"
        "netbird-dashboard"
        "netbird-server"
        "netbird-proxy"
        "netbird-crowdsec"
      ];
      routerLabels = name: service: rule: priority: {
        "traefik.http.routers.${name}.rule" = rule;
        "traefik.http.routers.${name}.entrypoints" = "websecure";
        "traefik.http.routers.${name}.tls" = "true";
        "traefik.http.routers.${name}.tls.certresolver" = "letsencrypt";
        "traefik.http.routers.${name}.service" = service;
        "traefik.http.routers.${name}.priority" = toString priority;
      };
    in
    {
      sops.secrets.cloudflare-acme-api-token = {
        sopsFile = ../secrets/cloudflare-acme.yaml;
        key = "api-token";
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "sugar@sne.moe";
        certs.netbird-proxy = {
          domain = "*.connect.sne.moe";
          extraDomainNames = [ "*.home.arpa.sne.moe" ];
          dnsProvider = "cloudflare";
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-acme-api-token.path;
          postRun = ''
            ${pkgs.coreutils}/bin/install -m 0600 -o 1000 -g 1000 \
              key.pem ${installPath}/data/netbird_proxy_certs/netbird-proxy.key
            ${pkgs.coreutils}/bin/install -m 0600 -o 1000 -g 1000 \
              fullchain.pem ${installPath}/data/netbird_proxy_certs/netbird-proxy.crt
          '';
          reloadServices = [ "podman-netbird-proxy.service" ];
        };
      };

      virtualisation.podman.dockerSocket.enable = true;

      virtualisation.oci-containers = {
        backend = "podman";
        containers =
          lib.mapAttrs
            (
              _: container:
              container
              // {
                # Podman supports a size cap, but not Docker's max-file option.
                log-driver = "k8s-file";
                extraOptions = (container.extraOptions or [ ]) ++ [
                  "--log-opt=max-size=500m"
                ];
              }
            )
            {
              netbird-traefik = {
                image = "docker.io/library/traefik:v3.6";
                networks = [ "netbird" ];
                extraOptions = [
                  "--ip=${traefikIP}"
                  "--network-alias=traefik"
                ];
                ports = [
                  "80:80"
                  "443:443"
                ];
                cmd = [
                  "--log.level=INFO"
                  "--accesslog=true"
                  "--providers.docker=true"
                  "--providers.docker.exposedbydefault=false"
                  "--providers.docker.network=netbird"
                  "--entrypoints.web.address=:80"
                  "--entrypoints.websecure.address=:443"
                  "--entrypoints.websecure.allowACMEByPass=true"
                  "--entrypoints.websecure.transport.respondingTimeouts.readTimeout=0"
                  "--entrypoints.websecure.transport.respondingTimeouts.writeTimeout=0"
                  "--entrypoints.websecure.transport.respondingTimeouts.idleTimeout=0"
                  "--entrypoints.web.http.redirections.entrypoint.to=websecure"
                  "--entrypoints.web.http.redirections.entrypoint.scheme=https"
                  "--certificatesresolvers.letsencrypt.acme.email=${acmeEmail}"
                  "--certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json"
                  "--certificatesresolvers.letsencrypt.acme.tlschallenge=true"
                  "--serverstransport.forwardingtimeouts.responseheadertimeout=0s"
                  "--serverstransport.forwardingtimeouts.idleconntimeout=0s"
                  "--providers.file.filename=/etc/traefik/dynamic.yaml"
                ];
                volumes = [
                  "/var/run/docker.sock:/var/run/docker.sock:ro"
                  "${installPath}/traefik-dynamic.yaml:/etc/traefik/dynamic.yaml:ro"
                  "${installPath}/data/netbird_traefik_letsencrypt:/letsencrypt"
                ];
              };

              netbird-dashboard = {
                image = "docker.io/netbirdio/dashboard:latest";
                extraOptions = [ "--network-alias=dashboard" ];
                labels = routerLabels "netbird-dashboard" "dashboard" "Host(`${domain}`)" 1 // {
                  "traefik.enable" = "true";
                  "traefik.http.services.dashboard.loadbalancer.server.port" = "80";
                };
                networks = [ "netbird" ];
                environmentFiles = [
                  "${installPath}/dashboard.env"
                ];
                volumes = [
                  "/etc/localtime:/etc/localtime:ro"
                ];
              };

              netbird-server = {
                image = "docker.io/netbirdio/netbird-server:latest";
                labels =
                  routerLabels "netbird-grpc" "netbird-server-h2c"
                    "Host(`${domain}`) && (PathPrefix(`/signalexchange.SignalExchange/`) || PathPrefix(`/management.ManagementService/`) || PathPrefix(`/management.ProxyService/`))"
                    100
                  //
                    routerLabels "netbird-backend" "netbird-server"
                      "Host(`${domain}`) && (PathPrefix(`/relay`) || PathPrefix(`/ws-proxy/`) || PathPrefix(`/api`) || PathPrefix(`/oauth2`))"
                      100
                  // {
                    "traefik.enable" = "true";
                    "traefik.http.services.netbird-server.loadbalancer.server.port" = "80";
                    "traefik.http.services.netbird-server-h2c.loadbalancer.server.port" = "80";
                    "traefik.http.services.netbird-server-h2c.loadbalancer.server.scheme" = "h2c";
                  };
                networks = [ "netbird" ];
                ports = [ "3478:3478/udp" ];
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
                networks = [ "netbird" ];
                ports = [ "51820:51820/udp" ];
                environmentFiles = [
                  "${installPath}/proxy.env"
                ];
                extraOptions = [ "--network-alias=proxy" ];
                labels = {
                  "traefik.enable" = "true";
                  "traefik.tcp.routers.proxy-passthrough.entrypoints" = "websecure";
                  "traefik.tcp.routers.proxy-passthrough.rule" = "HostSNI(`*`) && !HostSNI(`${domain}`)";
                  "traefik.tcp.routers.proxy-passthrough.tls.passthrough" = "true";
                  "traefik.tcp.routers.proxy-passthrough.service" = "proxy-tls";
                  "traefik.tcp.routers.proxy-passthrough.priority" = "1";
                  "traefik.tcp.services.proxy-tls.loadbalancer.server.port" = "8443";
                  "traefik.tcp.services.proxy-tls.loadbalancer.serverstransport" = "pp-v2@file";
                };
                volumes = [
                  "${installPath}/data/netbird_proxy_certs:/certs"
                ];
                dependsOn = [
                  "netbird-server"
                  "netbird-crowdsec"
                ];
              };

              netbird-crowdsec = {
                image = "docker.io/crowdsecurity/crowdsec:v1.7.7";
                podman.sdnotify = "healthy";
                extraOptions = [
                  "--network-alias=crowdsec"
                  "--health-cmd=cscli lapi status"
                  "--health-interval=10s"
                  "--health-timeout=5s"
                  "--health-retries=15"
                ];
                labels."traefik.enable" = "false";
                networks = [ "netbird" ];
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

      systemd.services = lib.mkMerge [
        (lib.genAttrs (map (name: "podman-${name}") containerNames) (_: {
          after = [ "podman-network-netbird.service" ];
          requires = [ "podman-network-netbird.service" ];
          serviceConfig.Restart = lib.mkForce "always";
        }))
        {
          podman-network-netbird = {
            description = "Create NetBird Podman network";
            after = [
              "network-online.target"
            ];
            wants = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${pkgs.podman}/bin/podman network exists netbird ||
                ${pkgs.podman}/bin/podman network create --driver=bridge \
                  --subnet=172.30.0.0/24 --gateway=172.30.0.1 netbird
            '';
          };
          podman-netbird-traefik = {
            after = [ "podman.socket" ];
            requires = [ "podman.socket" ];
          };
          podman-netbird-crowdsec.serviceConfig.TimeoutStartSec = lib.mkForce 300;
          acme-order-renew-netbird-proxy = {
            after = [ "sops-install-secrets.service" ];
            requires = [ "sops-install-secrets.service" ];
            serviceConfig.ReadWritePaths = [ "${installPath}/data/netbird_proxy_certs" ];
          };
          podman-netbird-proxy = {
            after = [
              "acme-order-renew-netbird-proxy.service"
            ];
            requires = [
              "acme-order-renew-netbird-proxy.service"
            ];
          };
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${installPath} 0751 root root -"
        "d ${installPath}/crowdsec 0750 root root -"
        "d ${installPath}/data 0751 root root -"
        "d ${installPath}/data/netbird_data 0750 root root -"
        "d ${installPath}/data/netbird_traefik_letsencrypt 0700 root root -"
        "d ${installPath}/data/netbird_proxy_certs 0700 1000 1000 -"
        "d ${installPath}/data/crowdsec_db 0750 root root -"
      ];
    };
}
