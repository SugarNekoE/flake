let
  installPath = "/opt/uptimekuma";
in
{
  nixos = { config, ... }: {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        uptime-kuma = {
          autoStart = true;
          image = "docker.io/louislam/uptime-kuma:2";
          ports = [ "3001:3001" ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${installPath}:/app/data"
          ];
        };
      };
    };

    environment.etc."timezone".text = "${config.time.timeZone}\n";

    systemd.tmpfiles.rules = [
      "d ${installPath} 0755 root root -"
    ];
  };
}
