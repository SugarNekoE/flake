{ inputs, ... }:
let
  withSecrets = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.monitoring ];
    nixosModule =
      { config, pkgs, ... }:
      let
        inherit (config.services.monitoring) containerUid;
        secret = key: {
          inherit sopsFile key;
          format = "yaml";
        };
        placeholder = config.sops.placeholder;
      in
      {
        sops.secrets = {
          grafana-admin-password = secret "grafana_admin_password";
          grafana-secret-key = secret "grafana_secret_key";
          grafana-oidc-client-id = secret "oidc_client_id";
          grafana-oidc-client-secret = secret "oidc_client_secret";
          grafana-telegram-bot-token = secret "telegram_bot_token";
          grafana-telegram-chat-id = secret "telegram_chat_id";
          clickhouse-default-password = secret "clickhouse-default-password";
          clickhouse-monitoring-db = secret "clickhouse-monitoring-db";
          clickhouse-monitoring-user = secret "clickhouse-monitoring-user";
          clickhouse-monitoring-password = secret "clickhouse-monitoring-password";
          otel-ingest-token = secret "otel-ingest-token";
          dtrack-kek = secret "dtrack_kek";
          dtrack-oidc-client-id = secret "dtrack_oidc_client_id";
          dtrack-exporter-api-key = secret "dtrack_exporter_api_key";
        };

        sops.templates = {
          "clickhouse-users.xml" = {
            uid = containerUid;
            gid = containerUid;
            restartUnits = [ "podman-clickhouse.service" ];
            content = ''
              <clickhouse>
                <profiles>
                  <default>
                    <network_compression_method>lz4</network_compression_method>
                  </default>
                </profiles>
                <users>
                  <default>
                    <password><![CDATA[${placeholder.clickhouse-default-password}]]></password>
                    <access_management>1</access_management>
                  </default>
                  <${placeholder.clickhouse-monitoring-user}>
                    <password><![CDATA[${placeholder.clickhouse-monitoring-password}]]></password>
                    <networks><ip>::/0</ip></networks>
                    <profile>default</profile>
                    <quota>default</quota>
                    <grants><query>GRANT ALL ON ${placeholder.clickhouse-monitoring-db}.*</query></grants>
                  </${placeholder.clickhouse-monitoring-user}>
                </users>
              </clickhouse>
            '';
          };

          "gigapipe.env" = {
            restartUnits = [ "podman-gigapipe.service" ];
            content = ''
              CLICKHOUSE_AUTH=${placeholder.clickhouse-monitoring-user}:${placeholder.clickhouse-monitoring-password}
              CLICKHOUSE_DB=${placeholder.clickhouse-monitoring-db}
            '';
          };

          "otel-collector.env" = {
            restartUnits = [ "opentelemetry-collector.service" ];
            content = ''
              OTEL_INGEST_TOKEN=${placeholder.otel-ingest-token}
            '';
          };

          "dtrack.env" = {
            restartUnits = [ "podman-dtrack-apiserver.service" ];
            content = ''
              DT_SECRET_MANAGEMENT_DATABASE_KEK=${placeholder.dtrack-kek}
              DT_OIDC_CLIENT_ID=${placeholder.dtrack-oidc-client-id}
            '';
          };

          "dtrack-frontend.env" = {
            restartUnits = [ "podman-dtrack-frontend.service" ];
            content = ''
              OIDC_CLIENT_ID=${placeholder.dtrack-oidc-client-id}
            '';
          };

          "dtrack-exporter.env" = {
            restartUnits = [ "dtrack-exporter.service" ];
            content = ''
              DEPENDENCY_TRACK_API_KEY=${placeholder.dtrack-exporter-api-key}
            '';
          };

          "grafana.env" = {
            restartUnits = [ "podman-grafana.service" ];
            content = ''
              GF_SECURITY_ADMIN_PASSWORD=${placeholder.grafana-admin-password}
              GF_SECURITY_SECRET_KEY=${placeholder.grafana-secret-key}
              GF_AUTH_GENERIC_OAUTH_CLIENT_ID=${placeholder.grafana-oidc-client-id}
              GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET=${placeholder.grafana-oidc-client-secret}
            '';
          };

          "grafana-contact-points.yaml" = {
            uid = containerUid;
            gid = containerUid;
            restartUnits = [ "podman-grafana.service" ];
            content = builtins.toJSON {
              apiVersion = 1;
              contactPoints = [
                {
                  orgId = 1;
                  name = "telegram";
                  receivers = [
                    {
                      uid = "telegram";
                      type = "telegram";
                      settings = {
                        bottoken = placeholder.grafana-telegram-bot-token;
                        chatid = placeholder.grafana-telegram-chat-id;
                      };
                    }
                  ];
                }
              ];
            };
          };
        };

        virtualisation.oci-containers.containers = {
          clickhouse = {
            environment.CLICKHOUSE_SKIP_USER_SETUP = "1";
            volumes = [
              "${
                config.sops.templates."clickhouse-users.xml".path
              }:/etc/clickhouse-server/users.d/monitoring.xml:ro"
            ];
          };
          gigapipe.environmentFiles = [ config.sops.templates."gigapipe.env".path ];
          grafana.environmentFiles = [ config.sops.templates."grafana.env".path ];
          dtrack-apiserver.environmentFiles = [ config.sops.templates."dtrack.env".path ];
          dtrack-frontend.environmentFiles = [ config.sops.templates."dtrack-frontend.env".path ];
        };

        systemd.services = {
          opentelemetry-collector.serviceConfig.EnvironmentFile =
            config.sops.templates."otel-collector.env".path;
          dtrack-exporter.serviceConfig.EnvironmentFile = config.sops.templates."dtrack-exporter.env".path;
        };

        services.monitoring.grafana = {
          provision = {
            "alerting/contactPoints.yaml" = config.sops.templates."grafana-contact-points.yaml".path;
            "alerting/policies.yaml" = (pkgs.formats.yaml { }).generate "policies.yaml" {
              apiVersion = 1;
              policies = [
                {
                  orgId = 1;
                  receiver = "telegram";
                  group_by = [
                    "grafana_folder"
                    "alertname"
                  ];
                }
              ];
            };
          };
        };
      };
  };
in
{
  aspectHelpers.monitoring = { inherit withSecrets; };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.monitoring;
      inherit (cfg) dtrack;
      blackbox = config.services.prometheus.exporters.blackbox;
      postgresExporter = config.services.prometheus.exporters.postgres;
      niks3 = config.services.niks3 or { enable = false; };
      adminGroup = "grafana_admin";
      ini = pkgs.formats.ini { };

      network = "monitoring";
      vmagentPort = 8429;
      gigapipePort = 3100;
      clickhouseMetricsPort = 9363;
      grafanaPort = 3000;
      otelHttpPort = 4318;
      dtrackApiPort = 8080;
      dtrackFrontendPort = 8081;
      dtrackManagementPort = 9002;
      dtrackExporterPort = 9916;
      local = port: "127.0.0.1:${toString port}";
      publish = port: "${toString port}:${toString port}";
      containerUser = "${toString cfg.containerUid}:${toString cfg.containerUid}";
      restartAlways = {
        startLimitIntervalSec = 0;
        serviceConfig = {
          Restart = lib.mkForce "always";
          RestartSec = "10s";
        };
      };

      nodeTargets =
        lib.mapAttrsToList
          (name: host: "${name}:${toString host.config.services.prometheus.exporters.node.port}")
          (
            lib.filterAttrs (
              _: host: host.config.services.prometheus.exporters.node.enable
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

      pveJob = targets: {
        job_name = "pve";
        metrics_path = "/pve";
        params = {
          target = [ "localhost" ];
          module = [ "default" ];
          cluster = [ "1" ];
          node = [ "1" ];
        };
        static_configs = [ { inherit targets; } ];
      };

      clickhouseConfig = pkgs.writeText "clickhouse-monitoring.xml" ''
        <clickhouse>
          <logger>
            <level>warning</level>
            <console>1</console>
            <log remove="remove"/>
            <errorlog remove="remove"/>
          </logger>
          <prometheus>
            <endpoint>/metrics</endpoint>
            <port>9363</port>
            <metrics>true</metrics>
            <events>true</events>
            <asynchronous_metrics>true</asynchronous_metrics>
          </prometheus>
          <max_server_memory_usage_to_ram_ratio>0.7</max_server_memory_usage_to_ram_ratio>
          <mark_cache_size>134217728</mark_cache_size>
          <index_mark_cache_size>67108864</index_mark_cache_size>
          <uncompressed_cache_size>0</uncompressed_cache_size>
          ${lib.concatMapStrings (table: ''<${table} remove="remove"/>'') [
            "asynchronous_metric_log"
            "asynchronous_insert_log"
            "background_schedule_pool_log"
            "blob_storage_log"
            "error_log"
            "latency_log"
            "metric_log"
            "opentelemetry_span_log"
            "part_log"
            "processors_profile_log"
            "query_log"
            "query_metric_log"
            "query_thread_log"
            "query_views_log"
            "session_log"
            "text_log"
            "trace_log"
          ]}
        </clickhouse>
      '';
    in
    {
      options.services.monitoring = {
        containerUid = lib.mkOption {
          type = lib.types.ints.unsigned;
          default = 1000;
          description = "UID and GID every monitoring container runs as and that owns their secrets and data.";
        };

        vmagent.dataDir = lib.mkOption {
          type = lib.types.str;
          default = "/var/lib/vmagent";
          description = "vmagent remote-write queue directory; must be below /var/lib.";
        };

        clickhouse.dataDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/clickhouse";
          description = "ClickHouse data directory.";
        };

        grafana = {
          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/grafana";
            description = "Grafana data directory.";
          };

          settings = lib.mkOption {
            inherit (ini) type;
            default = { };
            description = "Contents of grafana.ini.";
          };

          provision = lib.mkOption {
            type = lib.types.attrsOf lib.types.path;
            default = { };
            description = "Files placed in the Grafana provisioning directory, keyed by relative path.";
          };
        };

        retentionDays = lib.mkOption {
          type = lib.types.ints.positive;
          default = 90;
          description = "Days gigapipe keeps samples and labels.";
        };

        grafanaUrl = lib.mkOption {
          type = lib.types.str;
          description = "Public URL Grafana is served from.";
        };

        oidcIssuer = lib.mkOption {
          type = lib.types.str;
          description = "Pocket ID issuer URL used for Grafana and Dependency-Track login.";
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

        extraNodeTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Additional host:port node exporter targets outside this flake.";
        };

        pveTargets = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "host:port prometheus-pve-exporter targets; each exporter queries its own host's API.";
        };

        dtrack = {
          url = lib.mkOption {
            type = lib.types.str;
            description = "Public URL serving the frontend and, under /api, the API server.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/dependency-track";
            description = "Dependency-Track API server data directory.";
          };

          memory = lib.mkOption {
            type = lib.types.str;
            default = "1536m";
            description = "Memory limit of the API server container.";
          };

          database = {
            url = lib.mkOption {
              type = lib.types.str;
              default = "jdbc:postgresql://127.0.0.1:5432/dtrack";
              description = "JDBC URL of the PostgreSQL database.";
            };

            username = lib.mkOption {
              type = lib.types.str;
              description = "PostgreSQL user; authentication is left to the local proxy.";
            };
          };
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.hasPrefix "/var/lib/" cfg.vmagent.dataDir;
            message = "services.monitoring.vmagent.dataDir must be below /var/lib.";
          }
        ];

        users = {
          users.vmagent = {
            isSystemUser = true;
            group = "vmagent";
          };
          groups.vmagent = { };
        };

        services.vmagent = {
          enable = true;
          extraArgs = [
            "-httpListenAddr=:${toString vmagentPort}"
            "-remoteWrite.url=http://${local gigapipePort}/api/v1/prom/remote/write"
            "-remoteWrite.forcePromProto=true"
            "-remoteWrite.tmpDataPath=${cfg.vmagent.dataDir}/remote-write"
          ];
          prometheusConfig = {
            global.scrape_interval = "60s";
            scrape_configs = [
              (staticJob "node" (nodeTargets ++ cfg.extraNodeTargets))
              (staticJob "vmagent" [ (local vmagentPort) ])
              (staticJob "gigapipe" [ (local gigapipePort) ])
              (staticJob "clickhouse" [ (local clickhouseMetricsPort) ])
              (staticJob "dependency-track" [ (local dtrackManagementPort) ])
              (staticJob "dependency-track-exporter" [ (local dtrackExporterPort) ])
            ]
            ++ lib.optionals blackbox.enable [
              (blackboxJob "blackbox_http" "http_2xx" cfg.httpProbes)
              (blackboxJob "blackbox_tcp" "tcp_connect" cfg.tcpProbes)
            ]
            ++ lib.optional postgresExporter.enable (
              staticJob "postgres" [ "${postgresExporter.listenAddress}:${toString postgresExporter.port}" ]
            )
            ++ lib.optional niks3.enable (staticJob "niks3" [ niks3.httpAddr ])
            ++ lib.optional (cfg.pveTargets != [ ]) (pveJob cfg.pveTargets);
          };
        };

        services.opentelemetry-collector = {
          enable = true;
          package = pkgs.opentelemetry-collector-contrib;
          settings = {
            extensions.bearertokenauth.token = "\${env:OTEL_INGEST_TOKEN}";
            receivers.otlp.protocols.http = {
              endpoint = "0.0.0.0:${toString otelHttpPort}";
              auth.authenticator = "bearertokenauth";
            };
            processors.deltatocumulative = { };
            exporters.otlp_http = {
              endpoint = "http://${local gigapipePort}";
              compression = "none";
            };
            service = {
              extensions = [ "bearertokenauth" ];
              pipelines = {
                traces = {
                  receivers = [ "otlp" ];
                  exporters = [ "otlp_http" ];
                };
                metrics = {
                  receivers = [ "otlp" ];
                  processors = [ "deltatocumulative" ];
                  exporters = [ "otlp_http" ];
                };
              };
            };
          };
        };

        services.monitoring.grafana = {
          settings = {
            analytics = {
              reporting_enabled = false;
              check_for_updates = false;
            };
            server = {
              http_port = grafanaPort;
              root_url = cfg.grafanaUrl;
            };
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

        virtualisation.oci-containers = {
          backend = "podman";
          containers = {
            clickhouse = {
              autoStart = true;
              user = containerUser;
              image = "docker.io/clickhouse/clickhouse-server:26.10.3.7";
              networks = [ network ];
              ports = [
                "8123:8123"
                "9000:9000"
                (publish clickhouseMetricsPort)
              ];
              volumes = [
                "${cfg.clickhouse.dataDir}:/var/lib/clickhouse"
                "${clickhouseConfig}:/etc/clickhouse-server/config.d/monitoring.xml:ro"
              ];
              extraOptions = [ "--ulimit=nofile=262144:262144" ];
            };

            gigapipe = {
              autoStart = true;
              user = containerUser;
              image = "ghcr.io/metrico/gigapipe:v5.6.0";
              networks = [ network ];
              ports = [ (publish gigapipePort) ];
              dependsOn = [ "clickhouse" ];
              environment = {
                CLICKHOUSE_SERVER = "clickhouse";
                SAMPLES_DAYS = toString cfg.retentionDays;
                LABELS_DAYS = toString cfg.retentionDays;
                ADVANCED_SAMPLES_ORDERING = "fingerprint,timestamp_ns";
              };
            };

            grafana = {
              autoStart = true;
              image = "docker.io/grafana/grafana:13.0.12";
              user = containerUser;
              volumes = [
                "${cfg.grafana.dataDir}:/var/lib/grafana"
                "${ini.generate "grafana.ini" cfg.grafana.settings}:/etc/grafana/grafana.ini:ro"
              ]
              ++ lib.mapAttrsToList (
                name: path: "${path}:/etc/grafana/provisioning/${name}:ro"
              ) cfg.grafana.provision;
              extraOptions = [ "--network=host" ];
            };

            dtrack-apiserver = {
              autoStart = true;
              image = "ghcr.io/dependencytrack/apiserver:5.2.1";
              user = containerUser;
              volumes = [ "${dtrack.dataDir}:/data" ];
              environment = {
                DT_DATA_DIRECTORY = "/data";
                DT_DATASOURCE_URL = dtrack.database.url;
                DT_DATASOURCE_USERNAME = dtrack.database.username;
                DT_DATASOURCE_PASSWORD = "";
                DT_MANAGEMENT_HOST = "127.0.0.1";
                DT_MANAGEMENT_PORT = toString dtrackManagementPort;
                DT_METRICS_ENABLED = "true";
                DT_OUTBOUND_ALLOWED_DESTINATIONS = "external,127.0.0.1";
                DT_OIDC_ENABLED = "true";
                DT_OIDC_ISSUER = cfg.oidcIssuer;
                DT_OIDC_USERNAME_CLAIM = "preferred_username";
                DT_OIDC_USER_PROVISIONING = "true";
                DT_OIDC_TEAM_SYNCHRONIZATION = "true";
                DT_OIDC_TEAMS_CLAIM = "groups";
              };
              extraOptions = [
                "--network=host"
                "--memory=${dtrack.memory}"
              ];
            };

            dtrack-frontend = {
              autoStart = true;
              image = "ghcr.io/dependencytrack/frontend:5.2.1";
              ports = [ "${local dtrackFrontendPort}:8080" ];
              environment = {
                API_BASE_URL = dtrack.url;
                OIDC_ISSUER = cfg.oidcIssuer;
                OIDC_SCOPE = "openid profile email groups";
                OIDC_FLOW = "code";
                OIDC_LOGIN_BUTTON_TEXT = "Pocket ID";
              };
            };
          };
        };

        systemd.services = {
          podman-network-monitoring = {
            description = "Create monitoring Podman network";
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              ${lib.getExe pkgs.podman} network exists ${network} ||
                ${lib.getExe pkgs.podman} network create ${network}
            '';
          };

          podman-clickhouse = restartAlways // {
            after = [ "podman-network-monitoring.service" ];
            requires = [ "podman-network-monitoring.service" ];
          };

          podman-gigapipe = restartAlways // {
            after = [ "podman-network-monitoring.service" ];
            requires = [ "podman-network-monitoring.service" ];
          };

          podman-grafana = restartAlways;

          podman-dtrack-apiserver = restartAlways;

          podman-dtrack-frontend = restartAlways;

          dtrack-exporter = {
            description = "Dependency-Track Prometheus exporter";
            wantedBy = [ "multi-user.target" ];
            after = [ "podman-dtrack-apiserver.service" ];
            serviceConfig = {
              DynamicUser = true;
              Restart = "always";
              RestartSec = "10s";
              ExecStart = lib.escapeShellArgs [
                (lib.getExe pkgs.dependency-track-exporter)
                "--web.listen-address=${local dtrackExporterPort}"
                "--dtrack.address=http://${local dtrackApiPort}"
              ];
            };
          };

          opentelemetry-collector.after = [ "podman-gigapipe.service" ];

          vmagent = {
            after = [ "podman-gigapipe.service" ];
            serviceConfig = {
              DynamicUser = lib.mkForce false;
              StateDirectory = lib.removePrefix "/var/lib/" cfg.vmagent.dataDir;
            };
          };
        };
      };
    };
}
