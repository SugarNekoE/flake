_: {
  home =
    {
      config,
      pkgs,
      ...
    }:
    {
      stylix.targets.fcitx5.enable = true;

      home.sessionVariables = {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        QT_IM_MODULES = "wayland;fcitx";
        XMODIFIERS = "@im=fcitx";
      };

      systemd.user.sessionVariables = {
        GTK_IM_MODULE = "fcitx";
        QT_IM_MODULE = "fcitx";
        QT_IM_MODULES = "wayland;fcitx";
        XMODIFIERS = "@im=fcitx";
      };

      xdg.dataFile."fcitx5/rime/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/

          menu/page_size: 8

          schema_list:
            - schema: rime_ice
      '';

      xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml" = {
        text = ''
          patch:
            menu/page_size: 8
        '';
        onChange = ''
          ${pkgs.coreutils}/bin/rm -f \
            "${config.xdg.dataHome}/fcitx5/rime/build/rime_ice.schema.yaml"
        '';
      };

      i18n.inputMethod = {
        enable = true;
        type = "fcitx5";
        fcitx5 = {
          waylandFrontend = true;
          addons = with pkgs; [
            qt6Packages.fcitx5-configtool
            (fcitx5-rime.override {
              rimeDataPkgs = [ rime-ice ];
            })
          ];
          settings.inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "rime";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "rime";
          };
        };
      };

      systemd.user.services.fcitx5-daemon.Unit.X-Restart-Triggers = [
        config.xdg.configFile.fcitx5.source
        config.xdg.dataFile."fcitx5/rime/default.custom.yaml".source
        config.xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml".source
        config.xdg.dataFile."fcitx5/themes/stylix/theme.conf".source
        config.xdg.dataFile."fcitx5/themes/stylix/panel.svg".source
        config.xdg.dataFile."fcitx5/themes/stylix/highlight.svg".source
      ];

      systemd.user.services.fcitx5-daemon.Service.ExecStart =
        pkgs.lib.mkForce "${config.i18n.inputMethod.package}/bin/fcitx5 --replace";
    };
}
