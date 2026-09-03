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
          exec ${lib.getExe pkgs.forgejo-runner} one-job \
            --url "$(cat ${config.sops.secrets.forgejo-runner-url.path})" \
            --uuid "$(cat ${config.sops.secrets.forgejo-runner-uuid.path})" \
            --token-url "file://${config.sops.secrets.forgejo-runner-token.path}" \
            --label ${lib.escapeShellArg "nixos-latest:docker://nixos/nix:latest"} \
            --label ${lib.escapeShellArg "node-24:docker://node:24"} \
            --label ${lib.escapeShellArg "go:docker://golang:latest"} \
            --wait
        '';
      };
    };
}
