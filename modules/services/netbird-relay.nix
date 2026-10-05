let
  installPath = "/opt/netbird";
  domain = "relay-takoyaki.sne.moe";
in
{
  nixos =
    {
      config,
      pkgs,
      ...
    }:
    {
      sops.secrets.cloudflare-acme-api-token = {
        sopsFile = ../secrets/cloudflare-acme.yaml;
        key = "api-token";
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "sugar@sne.moe";
        certs.netbird-relay = {
          inherit domain;
          dnsProvider = "cloudflare";
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-acme-api-token.path;
          postRun = ''
            ${pkgs.coreutils}/bin/install -m 0644 fullchain.pem ${installPath}/certs/cert.pem
            ${pkgs.coreutils}/bin/install -m 0600 key.pem ${installPath}/certs/key.pem
          '';
          reloadServices = [ "podman-netbird-relay.service" ];
        };
      };

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          netbird-relay = {
            image = "docker.io/netbirdio/relay:latest";
            networks = [ "netbird-relay" ];
            ports = [
              "8443:8443"
              "[::]:8443:8443"
              "8443:8443/udp"
              "[::]:8443:8443/udp"
              "3478:3478/udp"
              "[::]:3478:3478/udp"
            ];
            environmentFiles = [
              "${installPath}/relay.env"
            ];
            volumes = [
              "${installPath}/data:/data"
              "${installPath}/certs:/certs"
            ];
          };
        };
      };

      systemd.services = {
        podman-network-netbird-relay = {
          description = "Create NetBird Relay Podman network";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            if ${pkgs.podman}/bin/podman network exists netbird-relay; then
              if [ "$(${pkgs.podman}/bin/podman network inspect --format '{{.IPv6Enabled}}' netbird-relay)" != true ]; then
                echo "NetBird Relay network is IPv4-only; stop its containers and recreate the network for IPv6." >&2
                exit 1
              fi
            else
              ${pkgs.podman}/bin/podman network create --driver=bridge \
                --subnet=172.31.0.0/24 --gateway=172.31.0.1 \
                --ipv6 --subnet=fd31:6e65:7462::/64 --gateway=fd31:6e65:7462::1 netbird-relay
            fi
          '';
        };

        podman-netbird-relay = {
          after = [ "podman-network-netbird-relay.service" ];
          requires = [ "podman-network-netbird-relay.service" ];
        };

        acme-order-renew-netbird-relay = {
          after = [ "sops-install-secrets.service" ];
          requires = [ "sops-install-secrets.service" ];
          serviceConfig.ReadWritePaths = [ "${installPath}/certs" ];
        };
      };

      systemd.tmpfiles.rules = [
        "f ${installPath}/data 0750 root root -"
        "d ${installPath}/certs 0750 root root -"
      ];
    };
}
