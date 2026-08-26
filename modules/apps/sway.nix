_: {
  nixos =
    { config, pkgs, ... }:
    let
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      programs.sway = {
        enable = true;
        package = pkgs.unstable.swayfx;
      };

      programs.gtklock = {
        enable = true;
        modules = [ pkgs.gtklock-userinfo-module ];
        config = {
          main = {
            background = toString config.stylix.image;
            gtk-theme = "Adwaita-dark";
            time-format = "%H:%M";
            date-format = "%A, %B %e";
          };
          userinfo.image-size = 128;
        };
        style = ''
          window {
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            background-color: ${colors.base00};
            color: ${colors.base05};
          }

          #window-box {
            padding: 36px 44px;
            border-radius: 28px;
            background-color: alpha(${colors.base00}, 0.82);
            border: 1px solid alpha(${colors.base05}, 0.16);
            box-shadow: 0 12px 36px alpha(#000000, 0.45);
          }

          #clock-label {
            font-size: 64pt;
            font-weight: 300;
            color: ${colors.base06};
            text-shadow: 0 2px 8px alpha(#000000, 0.65);
          }

          #date-label {
            margin-bottom: 18px;
            font-size: 16pt;
            color: ${colors.base05};
          }

          #user-image {
            margin-bottom: 8px;
          }

          #user-name {
            margin-bottom: 16px;
            font-size: 18pt;
            font-weight: 600;
            color: ${colors.base06};
          }

          #input-label {
            margin-right: 8px;
            color: ${colors.base05};
          }

          #input-field {
            min-height: 42px;
            padding: 0 16px;
            border-radius: 22px;
            border: 1px solid alpha(${colors.base05}, 0.28);
            background-color: alpha(${colors.base05}, 0.12);
            color: ${colors.base06};
            caret-color: ${colors.base06};
          }

          #input-field:focus {
            border-color: ${colors.base0D};
            box-shadow: 0 0 0 2px alpha(${colors.base0D}, 0.35);
          }

          #unlock-button {
            min-height: 42px;
            padding: 0 20px;
            border: 0;
            border-radius: 22px;
            background-color: ${colors.base0D};
            color: ${colors.base00};
            font-weight: 600;
          }

          #unlock-button:hover,
          #unlock-button:focus {
            background-color: ${colors.base0C};
          }

          #warning-label,
          #error-label {
            color: ${colors.base08};
          }
        '';
      };

      services.accounts-daemon.enable = true;

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

      services.displayManager.defaultSession = "sway-uwsm";

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
      lock = "${lib.getExe pkgs.gtklock} --daemonize";
      lockSession = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
    in
    {
      stylix.targets.sway.enable = true;
      services.swayidle = {
        enable = true;
        systemdTargets = [ "graphical-session.target" ];
        events = {
          lock = lock;
          before-sleep = lockSession;
        };
      };

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
        extraConfigEarly = "include /etc/sway/config.d/*";
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
            "${modifier}+l" = "exec ${lockSession}";
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
