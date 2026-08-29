_: {
  nixos =
    { pkgs, ... }:
    {
      systemd.services.fcitx5-resume = {
        description = "Restart Fcitx 5 after hibernation";
        after = [
          "hibernate.target"
          "suspend-then-hibernate.target"
        ];
        wantedBy = [
          "hibernate.target"
          "suspend-then-hibernate.target"
        ];
        serviceConfig.Type = "oneshot";
        script = ''
          for runtimeDir in /run/user/[0-9]*; do
            [[ -d "$runtimeDir" ]] || continue
            uid="''${runtimeDir##*/}"
            user="$(${pkgs.getent}/bin/getent passwd "$uid" | ${pkgs.coreutils}/bin/cut -d: -f1)"
            [[ -n "$user" ]] || continue

            ${pkgs.systemd}/bin/systemctl \
              --user --machine="$user@.host" \
              try-restart fcitx5-daemon.service || true
          done
        '';
      };
    };

  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      stylix.targets.fcitx5.enable = true;

      systemd.user.sessionVariables.XMODIFIERS = "@im=fcitx";

      home.packages = with pkgs; [
        setxkbmap
        xprop
      ];

      xdg.configFile."autostart/org.fcitx.Fcitx5.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';

      xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
        force = true;
        text = ''
          patch:
            __include: rime_ice_suggestion:/

            menu/page_size: 8

            schema_list:
              - schema: rime_ice
        '';
      };

      xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml" = {
        force = true;
        text = ''
          patch:
            menu/page_size: 8
        '';
        onChange = ''
          ${pkgs.coreutils}/bin/rm -f \
            "${config.xdg.dataHome}/fcitx5/rime/build/rime_ice.schema.yaml"
        '';
      };

      home.activation.makeRimeConfigMutable = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp --remove-destination \
          "${config.xdg.dataFile."fcitx5/rime/default.custom.yaml".source}" \
          "${config.xdg.dataHome}/fcitx5/rime/default.custom.yaml"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/cp --remove-destination \
          "${config.xdg.dataFile."fcitx5/rime/rime_ice.custom.yaml".source}" \
          "${config.xdg.dataHome}/fcitx5/rime/rime_ice.custom.yaml"
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod u+w \
          "${config.xdg.dataHome}/fcitx5/rime/default.custom.yaml" \
          "${config.xdg.dataHome}/fcitx5/rime/rime_ice.custom.yaml"

        if [[ -d "${config.xdg.dataHome}/fcitx5/rime/sync" ]]; then
          $DRY_RUN_CMD ${pkgs.findutils}/bin/find \
            "${config.xdg.dataHome}/fcitx5/rime/sync" \
            -type f -name '*.custom.yaml' \
            -exec ${pkgs.coreutils}/bin/chmod u+w {} +
        fi
      '';

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
