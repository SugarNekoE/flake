{ inputs, ... }:
let
  withDomain = domain: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.tailscale-derp ];
    nixosModule.services.tailscale.derper.domain = domain;
  };
in
{
  aspectHelpers.tailscale-derp = { inherit withDomain; };

  nixos =
    { config, ... }:
    {
      imports = [ inputs.self.modules.nixos.tailscale ];

      sops.secrets.cloudflare-acme-api-token = {
        sopsFile = ../secrets/cloudflare-acme.yaml;
        key = "api-token";
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "sugar@sne.moe";
        certs.tailscale-derp = {
          domain = config.services.tailscale.derper.domain;
          dnsProvider = "cloudflare";
          credentialFiles.CF_DNS_API_TOKEN_FILE = config.sops.secrets.cloudflare-acme-api-token.path;
          group = config.services.nginx.group;
        };
      };

      services.tailscale.derper = {
        enable = true;
        configureNginx = true;
        openFirewall = true;
        verifyClients = true;
      };

      services.nginx.virtualHosts.${config.services.tailscale.derper.domain} = {
        useACMEHost = "tailscale-derp";
        listen = [
          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
          {
            addr = "[::]";
            port = 8448;
            ssl = true;
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [ 8448 ];

      systemd.services.acme-order-renew-tailscale-derp = {
        after = [ "sops-install-secrets.service" ];
        requires = [ "sops-install-secrets.service" ];
      };
    };
}
