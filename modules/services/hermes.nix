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
          port = 9119;
        };
        settings = {
          dashboard.basic_auth = {
            username = "sugar";
            password_hash = "scrypt$16384$8$1$C9sx4GR9SIy5jeTm5FM25g==$NBMATAtxHlDZvNnTe63Sjju54NoaGbFFRo91wXZDN+w=";
          };
        };
      };
    };

  home = { lib, ... }: {
    imports = [ inputs.hermes-agent.homeManagerModules.default ];

    programs.hermes-agent = {
      enable = true;
      desktop.enable = true;
    };
  };
}
