{ inputs, ... }:
let
  withSecret = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.cloudflare-exporter ];
    nixosModule =
      { config, ... }:
      {
        sops.secrets.cloudflare-exporter-token = {
          inherit sopsFile;
          format = "yaml";
          key = "api_token";
          restartUnits = [ "cloudflare-exporter.service" ];
        };

        services.cloudflare-exporter.tokenFile = config.sops.secrets.cloudflare-exporter-token.path;
      };
  };
in
{
  aspectHelpers.cloudflare-exporter = { inherit withSecret; };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.cloudflare-exporter;
    in
    {
      options.services.cloudflare-exporter = {
        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "File containing a Cloudflare API token with analytics read access.";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 9199;
          description = "Local port the exporter listens on.";
        };

        freeTier = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Scrape only metrics available on the Cloudflare free plan.";
        };
      };

      config = lib.mkIf (cfg.tokenFile != null) {
        systemd.services.cloudflare-exporter = {
          description = "Prometheus Cloudflare exporter";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          environment = {
            LISTEN = "127.0.0.1:${toString cfg.port}";
            FREE_TIER = lib.boolToString cfg.freeTier;
          };

          script = ''
            CF_API_TOKEN="$(< "$CREDENTIALS_DIRECTORY/token")"
            export CF_API_TOKEN
            exec ${lib.getExe pkgs.prometheus-cloudflare-exporter}
          '';

          serviceConfig = {
            DynamicUser = true;
            LoadCredential = "token:${cfg.tokenFile}";
            Restart = "on-failure";
          };
        };
      };
    };
}
