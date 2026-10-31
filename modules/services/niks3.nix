{ inputs, ... }:
let
  withSecrets = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.niks3 ];
    nixosModule =
      { config, ... }:
      let
        secret = key: {
          inherit sopsFile key;
          format = "yaml";
          owner = "niks3";
          restartUnits = [ "niks3.service" ];
        };
      in
      {
        sops.secrets = {
          niks3-api-token = secret "api-token";
          niks3-signing-key = secret "signing-key";
          niks3-s3-access-key = secret "s3-access-key";
          niks3-s3-secret-key = secret "s3-secret-key";
        };

        services.niks3 = {
          apiTokenFile = config.sops.secrets.niks3-api-token.path;
          signKeyFiles = [ config.sops.secrets.niks3-signing-key.path ];
          s3 = {
            accessKeyFile = config.sops.secrets.niks3-s3-access-key.path;
            secretKeyFile = config.sops.secrets.niks3-s3-secret-key.path;
          };
        };
      };
  };
in
{
  flake-file.inputs.niks3.url = "github:Mic92/niks3";

  aspectHelpers.niks3 = { inherit withSecrets; };

  nixos = {
    imports = [ inputs.niks3.nixosModules.default ];

    services.niks3 = {
      enable = true;
      database.createLocally = false;
      s3.region = "auto";
    };
  };
}
