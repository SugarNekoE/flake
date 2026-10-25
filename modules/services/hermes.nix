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
        backend = {
          mode = "dashboard";
          host = "0.0.0.0";
        };
      };
    };
}
