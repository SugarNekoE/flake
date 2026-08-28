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
        ui.enable = false;

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

      systemd.services.netbird.serviceConfig = {
        StateDirectoryMode = lib.mkForce "2770";
        UMask = "0007";
      };

      systemd.tmpfiles.rules = [
        "z /var/lib/netbird/*.json 0660 netbird netbird - -"
      ];
    };

  home = { pkgs, ... }: {
    home.packages = [ pkgs.unstable.netbird-ui ];
  };
}
