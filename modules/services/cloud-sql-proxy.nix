{ inputs, ... }:
let
  withInstance = instance: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.cloud-sql-proxy ];
    nixosModule.services.cloud-sql-proxy.instance = instance;
  };
in
{
  aspectHelpers.cloud-sql-proxy = { inherit withInstance; };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.cloud-sql-proxy;
    in
    {
      options.services.cloud-sql-proxy = {
        instance = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Cloud SQL instance connection name (project:region:instance).";
        };

        port = lib.mkOption {
          type = lib.types.port;
          default = 5432;
          description = "Local port the proxy listens on.";
        };
      };

      config = lib.mkIf (cfg.instance != null) {
        systemd.services.cloud-sql-proxy = {
          description = "Cloud SQL Auth Proxy";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            DynamicUser = true;
            ExecStart = "${lib.getExe pkgs.google-cloud-sql-proxy} --auto-iam-authn --address 127.0.0.1 --port ${toString cfg.port} ${cfg.instance}";
            Restart = "on-failure";
          };
        };
      };
    };
}
