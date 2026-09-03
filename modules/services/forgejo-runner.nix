{ inputs, ... }:
let
  withConfig = { sopsFile, forgejoUrl }: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.forgejo-runner ];
    nixosModule = { config, ... }: {
      sops.secrets.forgejo-runner-token = {
        inherit sopsFile;
        format = "dotenv";
        key = "";
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
      networking,
      ...
    }:
    {
      services.gitea-actions-runner = {
        package = pkgs.forgejo-runner;
        instances.default = {
          enable = true;
          name = networking.hostName;
          url = withConfig.forgejoUrl;
          tokenFile = config.sops.secrets.forgejo-runner-token.path;
          labels = [
            "nixos-latest:docker://nixos/nix:latest"
            "node-24:docker://node:24"
            "go:docker://golang:latest"
          ];
        };
      };
    };
}
