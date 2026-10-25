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
        container = {
          enable = true;
          backend = "podman";
          image = "ubuntu:24.04";
          hostUsers = [ "${user.username}" ];
        };
      };
    };
}
