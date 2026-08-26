{
  nixos =
    {
      config,
      lib,
      user,
      ...
    }:
    let
      sopsFile = ../secrets/netbird.yaml;
      hasSetupKeys = builtins.pathExists sopsFile;
      clients = {
        home = {
          port = 51820;
          managementUrl = "https://connect.sne.moe:443";
        };
        atme = {
          port = 51821;
          managementUrl = "https://connect.techinteaching.cn:443";
        };
      };
      clientNames = builtins.attrNames clients;
      secretName = name: "netbird-setup-key-${name}";
    in
    {
      users.users.${user.username}.extraGroups = map (name: "netbird-${name}") clientNames;

      sops.secrets = lib.mkIf hasSetupKeys (
        lib.mapAttrs' (
          name: _client:
          lib.nameValuePair (secretName name) {
            inherit sopsFile;
            key = "netbird_setup_key/${name}";
            owner = "netbird-${name}";
            mode = "0400";
            restartUnits = [ "netbird-${name}-login.service" ];
          }
        ) clients
      );

      services.netbird = {
        ui.enable = true;
        clients = lib.mapAttrs (name: client: {
          inherit (client) port;
          environment.NB_MANAGEMENT_URL = client.managementUrl;
          ui.enable = true;
          login = lib.mkIf hasSetupKeys {
            enable = true;
            setupKeyFile = config.sops.secrets.${secretName name}.path;
            systemdDependencies = [ "sops-install-secrets.service" ];
          };
        }) clients;
      };
    };
}
