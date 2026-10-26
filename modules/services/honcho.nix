let
  installPath = "/var/lib/honcho";
in
{
  nixos = { config, ... }: {
    sops.secrets.honcho-env = {
      file = "../secrets/honcho.env";
      format = "env";
    };
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        honco-api = {
          autoStart = true;
          image = "ghcr.io/plastic-labs/honcho:latest";
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
        honco-deriver = {
          autoStart = true;
          image = "ghcr.io/plastic-labs/honcho:latest";
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
        honco-db = {
          autoStart = true;
          image = "docker.io/pgvector/pgvector:pg15";
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
        honco-redis = {
          autoStart = true;
          image = "docker.io/redis/redis:latest";
          volumes = [
            "${installPath}/redis-data:/data"
          ];
        };
      };
    };
  };
}
