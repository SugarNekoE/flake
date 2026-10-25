let
  installPath = "/var/lib/astrbot";
in
{
  nixos = {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        astrbot = {
          autoStart = true;
          image = "docker.io/soulter/astrbot:latest";
          ports = [
            "6185:6185"
            "6199:6199"
          ];
          volumes = [
            "${installPath}:/AstrBot/data"
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
          ];
          extraOptions = [
            "--security-opt=no-new-privileges:true"
          ];
        };
      };
    };
  };
}
