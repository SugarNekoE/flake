{ inputs, ... }:
let
  withSetupKey =
    {
      sopsFile,
      managementUrl,
      name ? "default",
      port ? 51820,
      interface ? "wt0",
    }:
    let
      secretName = "netbird-${name}-setup-key";
    in
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.netbird ];
      nixosModule =
        { pkgs, config, ... }:
        {
          sops.secrets.${secretName} = {
            format = "yaml";
            inherit sopsFile;
            key = "setup_key";
            restartUnits = [ "netbird-${name}-login.service" ];
          };

          services.netbird = {
            package = pkgs.unstable.netbird;
            clients.${name} = {
              inherit port;
              inherit interface;
              environment.NB_MANAGEMENT_URL = managementUrl;
              login = {
                enable = true;
                setupKeyFile = config.sops.secrets.${secretName}.path;
                systemdDependencies = [ "sops-install-secrets.service" ];
              };
            };
          };
        };
    };
in
{
  aspectHelpers.netbird = { inherit withSetupKey; };

  nixos = { };
}
