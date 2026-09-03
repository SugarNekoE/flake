{ inputs, ... }:
{
  flake-file.inputs.nekomonogatari-bot.url = "git+https://forge.asnk.io/sugar/nekomonogatari-bot";

  nixos = { config, ... }: {
    imports = [ inputs.nekomonogatari-bot.nixosModules.default ];

    nix.settings = {
      substituters = [ "https://nekomonogatari-bot.cachix.org" ];
      trusted-public-keys = [
        "nekomonogatari-bot.cachix.org-1:Opwduz2myeSTFELnIcJvvmJ97yofQJSdl5SBqrdUby0="
      ];
    };

    sops.secrets.nekomonogatari-bot = {
      sopsFile = ../secrets/nekomonogatari-bot.yaml;
      key = "";
      format = "yaml";
      owner = "nekomonogatari-bot";
    };

    services.nekomonogatari-bot = {
      enable = true;
      configPath = "${config.sops.secrets.nekomonogatari-bot.path}";
    };
  };
}
