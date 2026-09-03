let
  installPath = "/opt/mcsmanager";
in
{
  nixos = { config, pkgs, ... }: {
    systemd.services.podman-network-mcsm = {
      description = "Create MCSManager Podman network";

      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        ${pkgs.podman}/bin/podman network exists mcsm ||
          ${pkgs.podman}/bin/podman network create mcsm
      '';
    };

    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        mcsmanager-web = {
          autoStart = true;
          image = "docker.io/githubyumao/mcsmanager-web:latest";
          ports = [
            "23333:23333"
          ];
          volumes = [
            "/etc/localtime:/etc/localtime:ro"
            "${installPath}/web/data:/opt/mcsmanager/web/data"
            "${installPath}/web/logs:/opt/mcsmanager/web/logs"
          ];
        };

        mcsmanager-daemon = {
          autoStart = true;
          image = "docker.io/githubyumao/mcsmanager-daemon:latest";
          ports = [
            "24444:24444"
          ];
          environment = {
            MCSM_DOCKER_WORKSPACE_PATH = "/opt/mcsmanager/instance";
          };
          volumes = [
            "/etc/timezone:/etc/timezone:ro"
            "/etc/localtime:/etc/localtime:ro"
            "${installPath}/daemon/data:/opt/mcsmanager/daemon/data"
            "${installPath}/daemon/logs:/opt/mcsmanager/daemon/logs"
            "${installPath}/instance:/opt/mcsmanager/instance"
            "/run/docker.sock:/var/run/docker.sock"
          ];
        };
      };
    };

    environment.etc."timezone".text = "${config.time.timeZone}\n";

    systemd.tmpfiles.rules = [
      "d ${installPath} 0755 root root -"
      "d ${installPath}/web 0755 root root -"
      "d ${installPath}/web/data 0755 root root -"
      "d ${installPath}/web/logs 0755 root root -"
      "d ${installPath}/daemon 0755 root root -"
      "d ${installPath}/daemon/data 0755 root root -"
      "d ${installPath}/daemon/logs 0755 root root -"
      "d ${installPath}/instance 0755 root root -"
    ];
  };
}
