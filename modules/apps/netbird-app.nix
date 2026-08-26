_:
let
  profiles = {
    home = {
      displayName = "Home";
      managementUrl = "https://connect.sne.moe:443";
    };
    atme = {
      displayName = "Atme";
      managementUrl = "https://connect.techinteaching.cn:443";
    };
  };
in
{
  nixos =
    {
      config,
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
          ui.enable = false;
          openFirewall = true;
          openInternalFirewall = true;
        };
      };

      users.users.${user.username}.extraGroups = [
        config.services.netbird.clients.default.user.group
      ];
    };

  home =
    { lib, pkgs, ... }:
    let
      client = lib.getExe pkgs.unstable.netbird;
      uiPackage = pkgs.unstable.netbird-ui;
      ui = lib.getExe uiPackage;
      icon = "${uiPackage}/share/icons/hicolor/256x256/apps/netbird.png";
    in
    {
      home.packages = [ uiPackage ];

      xdg.desktopEntries.netbird = {
        name = "NetBird";
        genericName = "Mesh VPN";
        comment = "Connect to and switch between NetBird profiles";
        exec = "${lib.getExe' pkgs.coreutils "env"} WEBKIT_DISABLE_DMABUF_RENDERER=1 ${ui}";
        inherit icon;
        terminal = false;
        categories = [ "Network" ];
        startupNotify = false;
        settings = {
          Keywords = "netbird;vpn;home;atme;";
          StartupWMClass = "org.wails.netbird";
        };
        actions = lib.mapAttrs (name: profile: {
          name = "Set up or switch to ${profile.displayName}";
          exec = "${client} up --profile ${name} --management-url ${profile.managementUrl}";
          inherit icon;
        }) profiles;
      };
    };
}
