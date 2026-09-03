{ inputs, ... }:
let
  withConfig = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.forgejo-runner ];
    nixosModule = { config, ... }: {
      sops.secrets.forgejo-runner-config = {
        inherit sopsFile;
        format = "yaml";
        key = "";
        restartUnits = [ "forgejo-runner.service" ];
      };
    };
  };
in
{
  aspectHelpers.forgejo-runner = { inherit withConfig; };

  nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      systemd.services.forgejo-runner = {
        description = "Forgejo Actions Runner";

        wantedBy = [ "multi-user.target" ];

        after = [
          "network-online.target"
          "podman.service"
        ];

        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = "5s";
          WorkingDirectory = "/opt/forgejo-runner";
          StateDirectory = "forgejo-runner";
        };

        script = ''
          exec ${lib.getExe pkgs.forgejo-runner} daemon \
            --config ${config.sops.secrets.forgejo-runner-config.path}
        '';
      };

      systemd.tmpfiles.rules = [
        "d /opt/forgejo-runner 0755 root root -"
      ];
    };
}
