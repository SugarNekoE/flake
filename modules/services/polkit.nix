_: {
  nixos = {
    security.polkit.enable = true;
  };

  home =
    {
      lib,
      pkgs,
      ...
    }:
    let
      themePlugins = lib.makeSearchPath "lib/qt-6/plugins" [
        pkgs.kdePackages.qtstyleplugin-kvantum
        pkgs.qt6Packages.qt6ct
      ];
      themedAgent = pkgs.writeShellApplication {
        name = "lxqt-policykit-agent-themed";
        text = ''
          export QT_PLUGIN_PATH="${themePlugins}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
          exec ${lib.getExe pkgs.lxqt.lxqt-policykit} "$@"
        '';
      };
    in
    {
      systemd.user.services.lxqt-policykit-agent = {
        Unit = {
          Description = "LXQt PolicyKit Authentication Agent";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Environment = [
            "QT_QPA_PLATFORM=wayland;xcb"
            "QT_QPA_PLATFORMTHEME=qt6ct"
            "QT_STYLE_OVERRIDE=kvantum"
          ];
          ExecStart = lib.getExe themedAgent;
          Restart = "on-failure";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
