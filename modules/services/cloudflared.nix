{ inputs, ... }:
let
  withSecret = sopsFile: {
    _class = "aspects";
    imports = [ inputs.self.modules.aspects.cloudflared ];
    nixosModule =
      { config, ... }:
      {
        sops.secrets.cloudflared = {
          inherit sopsFile;
          format = "yaml";
          key = "secret";
          restartUnits = [ "cloudflared.service" ];
        };

        services.cloudflared.tokenFile = config.sops.secrets.cloudflared.path;
      };
  };
in
{
  aspectHelpers.cloudflared = { inherit withSecret; };

  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.cloudflared;
    in
    {
      options.services.cloudflared.tokenFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "File containing the token for a remotely managed Cloudflare tunnel.";
      };

      config = lib.mkIf (cfg.tokenFile != null) {
        services.cloudflared.enable = true;

        systemd.services.cloudflared = {
          description = "Cloudflare Tunnel client";
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            DynamicUser = true;
            LoadCredential = "token:${cfg.tokenFile}";
            ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token-file %d/token";
            Restart = "on-failure";
          };
        };
      };
    };
}
