{ inputs, ... }:
let
  withSetupKey =
    {
      sopsFile,
      managementUrl,
      name ? "default",
      port ? 51820,
    }:
    let
      secretName = "netbird-${name}-setup-key";
    in
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.netbird ];
      nixosModule =
        { config, ... }:
        {
          sops.secrets.${secretName} = {
            format = "yaml";
            inherit sopsFile;
            key = "setup_key";
            restartUnits = [ "netbird-${name}-login.service" ];
          };

          services.netbird.clients.${name} = {
            inherit port;
            environment.NB_MANAGEMENT_URL = managementUrl;
            login = {
              enable = true;
              setupKeyFile = config.sops.secrets.${secretName}.path;
              systemdDependencies = [ "sops-install-secrets.service" ];
            };
          };
        };
    };
in
{
  aspectHelpers.netbird = { inherit withSetupKey; };

  nixos = { };
}
