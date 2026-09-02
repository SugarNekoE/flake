{ inputs, ... }:
{
  flake-file.inputs.nekomonogatari-bot.url = "git+https://forge.asnk.io/sugar/nekomonogatari-bot";

  nixos = {
    imports = [ inputs.nekomonogatari-bot.nixosModules.default ];

    sops.secrets.nekomonogatari-bot = {
      sopsFile = ../secrets/nekomonogatari-bot.yaml;
      key = "";
      format = "yaml";
      path = "/run/secrets/nekomonogatari-bot.yaml";
      owner = "nekomonogatari-bot";
    };

    services.nekomonogatari-bot = {
      enable = true;
      configPath = "/run/secrets/nekomonogatari-bot.yaml";
    };
  };
}
