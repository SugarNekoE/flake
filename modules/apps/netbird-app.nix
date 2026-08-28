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
        StateDirectoryMode = lib.mkForce "0777";
      };
    };

  home =
    { lib, pkgs, ... }:
    let
      uiPackage = pkgs.unstable.netbird-ui;
      launcher = pkgs.writeShellScript "netbird-ui-launcher" ''
        if [[ "''${XDG_CURRENT_DESKTOP:-}" == *KDE* ]]; then
          export GDK_BACKEND=wayland
          export GDK_SCALE=1
          export GDK_DPI_SCALE=1
        fi
        exec ${lib.getExe uiPackage} --daemon-addr=unix:///run/netbird/sock
      '';
    in
    {
      home.packages = [ uiPackage ];

      xdg.desktopEntries.netbird = {
        name = "NetBird";
        genericName = "Mesh VPN";
        comment = "Connect to NetBird";
        exec = toString launcher;
        icon = "${uiPackage}/share/icons/hicolor/256x256/apps/netbird.png";
        terminal = false;
        categories = [ "Network" ];
        startupNotify = false;
        settings.StartupWMClass = "org.wails.netbird";
      };
    };
}
