{ inputs, ... }:
let
  withAuthKey =
    {
      sopsFile,
      key ? "auth_key",
    }:
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.tailscale ];
      nixosModule =
        { config, ... }:
        {
          sops.secrets.tailscale-auth-key = {
            format = "yaml";
            inherit sopsFile key;
            restartUnits = [ "tailscaled-autoconnect.service" ];
          };

          services.tailscale.authKeyFile = config.sops.secrets.tailscale-auth-key.path;

          systemd.services.tailscaled-autoconnect = {
            after = [ "sops-install-secrets.service" ];
            requires = [ "sops-install-secrets.service" ];
          };
        };
    };
in
{
  aspectHelpers.tailscale = { inherit withAuthKey; };

  nixos = {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
  };
}
