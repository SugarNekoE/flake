let
  installPath = "/var/lib/honcho";
in
{
  nixos = { config, pkgs, ... }: {
    sops.secrets.honcho-env = {
      sopsFile = ../secrets/honcho.env;
      format = "dotenv";
    };

    systemd.services.podman-network-honcho = {
      description = "Create Honcho Podman network";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.podman}/bin/podman network exists honcho ||
          ${pkgs.podman}/bin/podman network create honcho
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        honcho-api = {
          autoStart = true;
          image = "ghcr.io/plastic-labs/honcho:latest";
          networks = [ "honcho" ];
          ports = [ "8000:8000" ];
          cmd = [
            "sh"
            "docker/entrypoint.sh"
          ];
          volumes = [
            "${installPath}/lancedb:/app/lancedb_data"
          ];
          environmentFiles = [ "${config.sops.secrets.honcho-env.path}" ];
        };
        honcho-deriver = {
          autoStart = true;
          image = "ghcr.io/plastic-labs/honcho:latest";
          networks = [ "honcho" ];
          cmd = [
            "/app/.venv/bin/python"
            "-m"
            "src.deriver"
          ];
          volumes = [
            "${installPath}/lancedb:/app/lancedb_data"
          ];
          environmentFiles = [ "${config.sops.secrets.honcho-env.path}" ];
        };
        honcho-db = {
          autoStart = true;
          image = "docker.io/pgvector/pgvector:pg15";
          networks = [ "honcho" ];
          cmd = [
            "postgres"
            "-c"
            "max_connections=200"
          ];
          volumes = [
            "${installPath}/init.sql:/docker-entrypoint-initdb.d/init.sql"
            "${installPath}/pgdata:/var/lib/postgresql/data"
          ];
          environmentFiles = [ "${config.sops.secrets.honcho-env.path}" ];
        };
        honcho-redis = {
          autoStart = true;
          image = "docker.io/library/redis:8.2";
          networks = [ "honcho" ];
          volumes = [
            "${installPath}/redis-data:/data"
          ];
        };
      };
    };
  };
}
