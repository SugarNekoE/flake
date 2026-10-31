{ inputs, ... }:
{
  system = "x86_64-linux";
  imports = with inputs.self.aspects; [
    # system
    efi
    i18n
    gce

    # roles
    base
    server

    # services
    gcp-ops-agent
    blackbox-exporter
    (cloud-sql-proxy.withInstance "project-48516ea4-5e61-4dea-8a1:us-central1:amber-db")
    (niks3.withSecrets ../secrets/niks3.yaml)
    (cloudflared.withSecret ../secrets/cloudflared/amber.yaml)
    (tailscale.withAuthKey ../secrets/tailscale/sne-moe.yaml)
    (monitoring.withSecrets ../secrets/monitoring.yaml)
    (cloudflare-exporter.withSecret ../secrets/cloudflare-exporter.yaml)
  ];
  diskoConfig = inputs.self.diskoConfigurations.xfs-with-quota;
  nixos =
    {
      config,
      identity,
      lib,
      pkgs,
      utils,
      ...
    }:
    let
      monitoringDisk = "/mnt/monitoring";
      inherit (config.services.monitoring) victoriametrics grafana;
      bindMounts = {
        ${victoriametrics.dataDir} = "${monitoringDisk}/victoriametrics";
        ${grafana.dataDir} = "${monitoringDisk}/grafana";
      };
      bindMountUnits = map (path: "${utils.escapeSystemdPath path}.mount") (lib.attrNames bindMounts);
    in
    {
      users.users.root.openssh.authorizedKeys.keys = [ identity.sshKeys.sugar ];

      zramSwap.enable = true;

      fileSystems = {
        ${monitoringDisk} = {
          device = "/dev/disk/by-id/google-monitoring";
          fsType = "xfs";
          autoFormat = true;
          autoResize = true;
        };
      }
      // lib.mapAttrs (_: device: {
        inherit device;
        fsType = "none";
        options = [ "bind" ];
        depends = [ monitoringDisk ];
      }) bindMounts;

      systemd = {
        services = {
          monitoring-dirs = {
            unitConfig = {
              DefaultDependencies = false;
              RequiresMountsFor = monitoringDisk;
            };
            before = bindMountUnits;
            requiredBy = bindMountUnits;
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = "mkdir -p ${lib.concatStringsSep " " (lib.attrValues bindMounts)}";
          };

          monitoring-growfs = {
            serviceConfig.Type = "oneshot";
            script = "${lib.getExe' pkgs.xfsprogs "xfs_growfs"} ${monitoringDisk}";
          };

          victoriametrics.unitConfig.RequiresMountsFor = [ victoriametrics.dataDir ];

          grafana = {
            after = [ "cloud-sql-proxy.service" ];
            requires = [ "cloud-sql-proxy.service" ];
            unitConfig.RequiresMountsFor = [ grafana.dataDir ];
          };
        };

        tmpfiles.settings.grafana-data.${grafana.dataDir}.d = {
          user = "grafana";
          group = "grafana";
          mode = "0700";
        };

        timers.monitoring-growfs = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
          };
        };
      };

      services.monitoring = {
        victoriametrics.dataDir = "/var/lib/victoriametrics";
        grafana.dataDir = "/var/lib/grafana";
        grafanaUrl = "https://mon.asnk.io";
        oidcIssuer = "https://id.sne.moe";
        httpProbes = [
          "https://sne.moe"
          "https://cv.sne.moe"
          "https://food.sne.moe"
          "https://id.sne.moe/healthz"
          "https://sh-derp.sne.moe:8448"
          "https://forge.asnk.io/api/healthz"
          "https://cache.asnk.io/nix-cache-info"
          "https://mon.asnk.io/api/health"
          "https://ignisnet.co"
          "https://adguard.dwelf-hoki.ts.net"
          "https://hass.dwelf-hoki.ts.net"
          "https://immich.dwelf-hoki.ts.net"
          "https://jellyfin.dwelf-hoki.ts.net"
        ];
      };

      services.grafana.settings.database = {
        type = "postgres";
        host = "127.0.0.1:5432";
        name = "grafana";
        user = "amber-vm@project-48516ea4-5e61-4dea-8a1.iam";
        ssl_mode = "disable";
      };

      services.niks3 = {
        s3 = {
          endpoint = "297bf25f648e310a3564843054342e44.r2.cloudflarestorage.com";
          bucket = "amber";
        };
        cacheUrl = "https://cache.asnk.io";
        serverUrl = "https://amber.asnk.io";
        database.connectionString = "postgres://amber-vm%40project-48516ea4-5e61-4dea-8a1.iam@127.0.0.1:5432/niks3?sslmode=disable";
        oidc.providers.forgejo = {
          issuer = "https://forge.asnk.io/api/actions";
          audience = "https://amber.asnk.io";
          boundClaims.repository_owner = [ "sugar" ];
        };
      };

      systemd.services.niks3 = {
        after = [ "cloud-sql-proxy.service" ];
        requires = [ "cloud-sql-proxy.service" ];
      };
    };
}
