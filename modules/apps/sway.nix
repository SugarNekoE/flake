_: {
  nixos =
    { pkgs, ... }:
    {
      programs.sway = {
        enable = true;
        package = pkgs.unstable.swayfx;
      };

      programs.uwsm = {
        enable = true;
        waylandCompositors = {
          sway = {
            prettyName = "Sway";
            comment = "Sway compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/sway";
          };
        };
      };

      systemd.user.targets."nixos-fake-graphical-session".enable = false;
    };

  flake.modules.homeManager.sway =
    {
      lib,
      nixosConfig,
      pkgs,
      ...
    }:
    let
      menu = "vicinae toggle";
      modifier = "Mod4";
      terminal = "kitty";
      filemanager = "dolphin";
      browser = "google-chrome-stable";
      screenshot = "grimshot copy anything";
    in
    {
      systemd.user.services.fcitx5-daemon = {
        Unit = {
          PartOf = [ "sway-session.target" ];
          After = [ "sway-session.target" ];
        };
        Install.WantedBy = [ "sway-session.target" ];
      };

      wayland.windowManager.sway = {
        enable = true;
        systemd.enable = false; # UWSM managed
        package = pkgs.unstable.swayfx;
        # SwayFX requires a DRM renderer even for its config check, which is unavailable in the build sandbox.
        checkConfig = false;
        wrapperFeatures.gtk = true;
        config = {
          defaultWorkspace = "workspace number 1";
          startup = [
            { command = "1password --silent"; }
            {
              command = "autotiling";
              always = true;
            }
          ];
          inherit menu modifier terminal;
          bars = [ ];
          gaps.smartBorders = "on";
          input."*" = {
            natural_scroll = "enabled";
          };
          input."type:keyboard" = {
            xkb_layout = nixosConfig.services.xserver.xkb.layout;
            xkb_options = nixosConfig.services.xserver.xkb.options;
          };
          workspaceAutoBackAndForth = true;
          window = {
            titlebar = false;
            border = 2;
          };
          floating.titlebar = false;
          focus.followMouse = false;
          keybindings = lib.mkOptionDefault {
            "${modifier}+b" = "exec ${browser}";
            "${modifier}+e" = "exec ${filemanager}";
            "${modifier}+Shift+s" = "exec ${screenshot}";
            "${modifier}+Return" = "exec ${terminal}";
            "${modifier}+d" = "exec ${menu}";
            "${modifier}+Shift+q" = "kill";
            "${modifier}+space" = "focus mode_toggle";
          };
        };
        extraConfig = ''
          seat * hide_cursor when-typing enable
          blur enable
          default_dim_inactive 0.2
          exec uwsm finalize
        '';
      };

      home.packages = with pkgs; [
        brightnessctl
        wl-clipboard
        sway-contrib.grimshot
        kdePackages.dolphin
        autotiling
        wdisplays
      ];

      services.gnome-keyring.enable = true;
      services.mako.enable = true;
    };
}
