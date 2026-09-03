{ inputs, ... }:
let
  installPath = "/opt/pocket-id";
  withEnvFile = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.pocket-id ];
    nixosModule = { config, ... }: {
      sops.secrets.pocket-id = {
        inherit sopsFile;
        format = "dotenv";
        key = "";
        restartUnits = [ "podman-pocket-id.service" ];
      };
    };
  };
in
{
  aspectHelpers.pocket-id = { inherit withEnvFile; };

  nixos = { config, pkgs, ... }: {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        pocket-id = {
          autoStart = true;
          image = "ghcr.io/pocket-id/pocket-id:v2";
          ports = [
            "1411:1411"
          ];
          environmentFiles = [ "${config.sops.secrets.pocket-id.path}" ];
          volumes = [
            "/etc/timezone:/etc/timezone:ro"
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
