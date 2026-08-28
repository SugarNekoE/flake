_: {
  nixos =
    {
      config,
      lib,
      pkgs,
      user,
      ...
    }:
    {
      services.resolved.enable = true;

      services.netbird = {
        package = pkgs.unstable.netbird;
        ui = {
          enable = true;
          package = pkgs.unstable.netbird-ui;
        };

        clients.default = {
          name = "netbird";
          interface = "wt0";
          port = 51820;
          environment.NB_CONFIG = lib.mkForce "/var/lib/netbird/default.json";
          openFirewall = true;
          openInternalFirewall = true;
        };
      };

      users.users.${user.username}.extraGroups = [
        config.services.netbird.clients.default.user.group
      ];
    };
}
