{ inputs, ... }:
let
  withSecrets = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.monitoring ];
    nixosModule =
      { config, ... }:
      let
        secret = key: {
          inherit sopsFile key;
          format = "yaml";
          owner = "grafana";
          restartUnits = [ "grafana.service" ];
        };
        file = name: "$__file{${config.sops.secrets.${name}.path}}";
      in
      {
        sops.secrets = {
          grafana-admin-password = secret "grafana_admin_password";
          grafana-secret-key = secret "grafana_secret_key";
          grafana-oidc-client-id = secret "oidc_client_id";
          grafana-oidc-client-secret = secret "oidc_client_secret";
        };

        services.grafana.settings = {
          security = {
            admin_password = file "grafana-admin-password";
            secret_key = file "grafana-secret-key";
          };
          "auth.generic_oauth" = {
            client_id = file "grafana-oidc-client-id";
            client_secret = file "grafana-oidc-client-secret";
          };
        };
      };
  };
in
{
  aspectHelpers.monitoring = { inherit withSecrets; };

  nixos =
    { config, lib, ... }:
    let
      cfg = config.services.monitoring;
      victoriametrics = config.services.victoriametrics;
      blackbox = config.services.prometheus.exporters.blackbox;
      cloudflareExporter = config.services.cloudflare-exporter or { tokenFile = null; };
      adminGroup = "grafana_admin";

      nodeTargets =
        lib.mapAttrsToList
          (name: host: "${name}:${toString host.config.services.prometheus.exporters.node.port}")
          (
            lib.filterAttrs (
              _: host:
              host.config.services.tailscale.enable && host.config.services.prometheus.exporters.node.enable
            ) inputs.self.nixosConfigurations
          );

      staticJob = name: targets: {
        job_name = name;
        static_configs = [ { inherit targets; } ];
      };

      blackboxJob = name: module: targets: {
        job_name = name;
        metrics_path = "/probe";
        params.module = [ module ];
        static_configs = [ { inherit targets; } ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "${blackbox.listenAddress}:${toString blackbox.port}";
          }
        ];
      };
    in
    {
      options.services.monitoring = {
        victoriametrics.dataDir = lib.mkOption {
          type = lib.types.str;
          description = "VictoriaMetrics storage directory; must be below /var/lib.";
        };

        grafana.dataDir = lib.mkOption {
          type = lib.types.path;
          description = "Grafana data directory.";
        };

        grafanaUrl = lib.mkOption {
          type = lib.types.str;
          description = "Public URL Grafana is served from.";
        };

        oidcIssuer = lib.mkOption {
          type = lib.types.str;
          description = "Pocket ID issuer URL used for Grafana login.";
        };

        httpProbes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "URLs the blackbox exporter expects a 2xx response from.";
        };

        tcpProbes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "host:port targets the blackbox exporter opens a TCP connection to.";
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.hasPrefix "/var/lib/" cfg.victoriametrics.dataDir;
            message = "services.monitoring.victoriametrics.dataDir must be below /var/lib.";
          }
        ];

        users = {
          users.victoriametrics = {
            isSystemUser = true;
            group = "victoriametrics";
          };
          groups.victoriametrics = { };
        };

        systemd.services.victoriametrics.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "victoriametrics";
          Group = "victoriametrics";
        };

        services.victoriametrics = {
          enable = true;
          stateDir = lib.removePrefix "/var/lib/" cfg.victoriametrics.dataDir;
          listenAddress = "127.0.0.1:8428";
          retentionPeriod = "1y";
          extraOptions = [ "-storage.minFreeDiskSpaceBytes=512MB" ];
          prometheusConfig = {
            global.scrape_interval = "60s";
            scrape_configs = [
              (staticJob "node" nodeTargets)
              (staticJob "victoriametrics" [ victoriametrics.listenAddress ])
            ]
            ++ lib.optionals blackbox.enable [
              (blackboxJob "blackbox_http" "http_2xx" cfg.httpProbes)
              (blackboxJob "blackbox_tcp" "tcp_connect" cfg.tcpProbes)
            ]
            ++ lib.optional (cloudflareExporter.tokenFile != null) (
              staticJob "cloudflare" [ "127.0.0.1:${toString cloudflareExporter.port}" ]
            );
          };
        };

        services.grafana = {
          enable = true;
          inherit (cfg.grafana) dataDir;
          settings = {
            server.root_url = cfg.grafanaUrl;
            "auth.generic_oauth" = {
              enabled = true;
              name = "Pocket ID";
              scopes = "openid email profile groups";
              auth_url = "${cfg.oidcIssuer}/authorize";
              token_url = "${cfg.oidcIssuer}/api/oidc/token";
              api_url = "${cfg.oidcIssuer}/api/oidc/userinfo";
              use_pkce = true;
              allow_sign_up = true;
              login_attribute_path = "preferred_username";
              email_attribute_path = "email";
              name_attribute_path = "name";
              role_attribute_path = "contains(groups[*], '${adminGroup}') && 'Admin' || 'Viewer'";
            };
          };
        };
      };
    };
}
