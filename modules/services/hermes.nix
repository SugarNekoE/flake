{ inputs, ... }:
{
  flake-file.inputs.hermes-agent.url = "github:NousResearch/hermes-agent";

  nixos =
    {
      pkgs,
      config,
      user,
      ...
    }:
    {
      imports = [ inputs.hermes-agent.nixosModules.default ];

      sops.secrets.hermes-env = {
        sopsFile = ../secrets/hermes.yaml;
        format = "yaml";
      };

      services.hermes-agent = {
        enable = true;
        environmentFiles = [ config.sops.secrets.hermes-env.path ];
        addToSystemPackages = true;
        container = {
          enable = true;
          backend = "podman";
          image = "ubuntu:24.04";
          hostUsers = [ "${user.username}" ];
        };
      };

      security.sudo.extraRules = [
        {
          users = [ "${user.username}" ];
          commands = [
            {
              command = "/run/current-system/sw/bin/podman";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };
  home = { lib, ... }: {
    imports = [ inputs.hermes-agent.homeManagerModules.default ];

    programs.hermes-agent = {
      enable = true;
      desktop.enable = true;
    };
  };
}
