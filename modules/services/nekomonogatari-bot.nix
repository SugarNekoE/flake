_: {
  flake-file.inputs.nekomonogatari-bot.url = "git+https://forge.asnk.io/sugar/nekomonogatari-bot";

  nixos = { lib, ... }: {
    sops.secrets.nekomonogatari-bot = {
      sopsFile = "../secrets/nekomonogatari-bot.yaml";
      key = "";
      format = "yaml";
      path = "/run/secrets/nekomonogatari-bot.yaml";
    };

    services.nekomonogatari-bot = {
      enable = true;
      configPath = "/run/secrets/nekomonogatari-bot.yaml";
    };
  };
}
