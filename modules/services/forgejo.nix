let
  installPath = "/opt/forgejo";
  dataPath = "/mnt/data";
in
{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      caddy = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/mholt/caddy-l4@v0.1.1"
        ];
        hash = "sha256-hDGhrMLxrjNdNaCp+oT1WPfA9ty5Ltw2gkVt1Z48q7g=";
      };

      caddyBase = pkgs.dockerTools.pullImage {
        imageName = "docker.io/library/caddy";
        imageDigest = "sha256:98eb57d882ccd5213d1688764db10c1ca2c58a1ca3a6717a3411ad798f7a423a";
        finalImageName = "caddy";
        finalImageTag = "2";
        hash = "sha256-0uWUw2BoxCMNEP0xCSzaE2k7TiQkT0CrBN5YT2G2prE=";
      };

      caddyImage = pkgs.dockerTools.buildImage {
        name = "caddy-l4";
        tag = "latest";

        fromImage = caddyBase;

        copyToRoot = pkgs.runCommand "caddy-overlay" { } ''
          mkdir -p $out/usr/bin
          cp ${caddy}/bin/caddy $out/usr/bin/caddy
        '';

        config = {
          Cmd = [
            "/usr/bin/caddy"
            "run"
            "--config"
            "/etc/caddy/Caddyfile"
          ];
        };
      };
    in
    {
      systemd.services.podman-network-forgejo = {
        description = "Create Forgejo Podman network";

        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          ${pkgs.podman}/bin/podman network exists forgejo ||
            ${pkgs.podman}/bin/podman network create forgejo
        '';
      };

      virtualisation.oci-containers = {
        backend = "podman";
        containers = {
          caddy = {
            autoStart = true;
            image = "caddy-l4:latest";
            imageFile = caddyImage;
            ports = [
              "80:80"
              "443:443"
              "22:22"
            ];
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${installPath}/caddy/Caddyfile:/etc/caddy/Caddyfile"
              "${installPath}/caddy/data:/data"
              "${installPath}/caddy/config:/config"
            ];
            networks = [ "forgejo" ];
            dependsOn = [ "anubis" ];
          };

          anubis = {
            autoStart = true;
            image = "ghcr.io/techarohq/anubis:latest";
            pull = "always";
            environment = {
              BIND = ":8080";
              TARGET = "http://server:3000";
              DIFFICULTY = "4";
              SERVE_ROBOTS_TXT = "true";
            };
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
            ];
            networks = [ "forgejo" ];
            dependsOn = [ "server" ];
          };

          server = {
            autoStart = true;
            image = "codeberg.org/forgejo/forgejo:16";
            environmentFiles = [
              "${installPath}/server.env"
            ];
            environment = {
              USER_UID = "1000";
              USER_GID = "1000";
            };
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${installPath}/forgejo:/data"
              "${dataPath}:/storage"
            ];
            networks = [ "forgejo" ];
            dependsOn = [ "db" ];
          };

          db = {
            autoStart = true;
            image = "docker.io/library/postgres:14";
            environmentFiles = [
              "${installPath}/db.env"
            ];
            networks = [ "forgejo" ];
            volumes = [
              "${installPath}/postgres:/var/lib/postgresql/data"
            ];
          };
        };
      };

      environment.etc."timezone".text = "${config.time.timeZone}\n";

      systemd.tmpfiles.rules = [
        "d ${installPath} 0755 root root -"
        "d ${installPath}/caddy 0755 1000 1000 -"
        "f ${installPath}/caddy/Caddyfile 0644 root root -"
        "d ${installPath}/caddy/data 0755 1000 1000 -"
        "d ${installPath}/caddy/config 0755 1000 1000 -"
        "d ${installPath}/postgres 0755 999 999 -"
        "d ${installPath}/forgejo 0755 1000 1000 -"
        "d ${dataPath} 0755 root root -"
      ];
    };
}
