{ inputs, ... }:
let
  withConfig = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.forgejo-runner ];
    nixosModule = { config, ... }: {
      sops.secrets = {
        forgejo-runner-url = {
          inherit sopsFile;
          format = "yaml";
          key = "url";
        };
        forgejo-runner-uuid = {
          inherit sopsFile;
          format = "yaml";
          key = "uuid";
        };
        forgejo-runner-token = {
          inherit sopsFile;
          format = "yaml";
          key = "token";
        };
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
        description = "Ephemeral Forgejo Actions Runner";

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
          WorkingDirectory = "/var/lib/forgejo-runner";
          StateDirectory = "forgejo-runner";
        };

        path = [
          pkgs.coreutils
          pkgs.podman
        ];

        preStart = ''
          cd /var/lib/forgejo-runner
          rm -f .runner
          ${lib.getExe pkgs.forgejo-runner} register \
            --no-interactive \
            --url "$(cat ${config.sops.secrets.forgejo-runner-url.path})" \
            --uuid "$(cat ${config.sops.secrets.forgejo-runner-uuid.path})" \
            --token-url "file://${config.sops.secrets.forgejo-runner-token.path}" \
            --labels ${
              lib.escapeShellArg (
                lib.concatStringsSep "," [
                  "nixos-latest:docker://nixos/nix:latest"
                  "node-24:docker://node:24"
                  "go:docker://golang:latest"
                ]
              )
            }
        '';

        script = ''
          exec ${lib.getExe pkgs.forgejo-runner} one-job
        '';
      };
    };
}
