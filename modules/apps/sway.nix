_: {
  nixos =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.sway = {
        enable = true;
        package = pkgs.unstable.swayfx;
      };

      services.accounts-daemon.enable = true;
      services.tumbler.enable = true;

      programs.thunar = {
        enable = true;
        plugins = [ pkgs.thunar-volman ];
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

      services.displayManager.defaultSession = "sway-uwsm";

      xdg.portal.wlr.settings.screencast = {
        chooser_type = "dmenu";
        chooser_cmd = "${lib.getExe pkgs.wmenu} -p 'Select a source to share:'";
      };

      systemd.user.targets."nixos-fake-graphical-session".enable = false;
    };

  flake.modules.homeManager.sway =
    {
      config,
      lib,
      nixosConfig,
      pkgs,
      ...
    }:
    let
      menu = "${lib.getExe config.programs.vicinae.package} toggle";
      modifier = "Mod4";
      terminal = "kitty";
      filemanager = lib.getExe pkgs.thunar;
      browser = "google-chrome-stable";
      screenshot = "grimshot copy anything";
      screenshotArea = "grimshot --notify savecopy area";
      screenshotScreen = "grimshot --notify savecopy screen";
      screenshotWindow = "grimshot --notify savecopy active";
      lockScreen = lib.getExe config.programs.swaylock.package;
      lidDisplayControl = pkgs.writeShellApplication {
        name = "lid-display-control";
        runtimeInputs = [ pkgs.unstable.swayfx ];
        text = ''
          action="''${1:?expected close or open}"

          if [[ "$action" == "close" ]]; then
            on_ac_power=false
            for supply in /sys/class/power_supply/*; do
              if [[ -r "$supply/type" && -r "$supply/online" ]] \
                && [[ "$(<"$supply/type")" == "Mains" ]] \
                && [[ "$(<"$supply/online")" == "1" ]]; then
                on_ac_power=true
                break
              fi
            done

            [[ "$on_ac_power" == true ]] || exit 0
            power_state="off"
          elif [[ "$action" == "open" ]]; then
            power_state="on"
          else
            echo "unknown lid action: $action" >&2
            exit 2
          fi

          swaymsg "output * power $power_state"
        '';
      };
    in
    {
      stylix.targets.sway.enable = true;
      stylix.targets.mako.enable = true;
      services.swayidle = {
        enable = true;
        systemdTargets = [ "graphical-session.target" ];
        events = {
          lock = lockScreen;
          before-sleep = lockScreen;
        };
      };
      services.stasis = {
        extraPathPackages = [
          config.programs.swaylock.package
          lidDisplayControl
          pkgs.unstable.swayfx
        ];
        extraConfig = ''
          @author "sugar"
          @description "Sway idle management"

          default:
            enable_loginctl_integration true
            enable_dbus_inhibit true
            lid_close_action "lid-display-control close"
            lid_open_action "lid-display-control open"
            monitor_media true
            ignore_remote_media true
            notify_on_unpause true

            lock_screen:
              timeout 1800
              command "swaylock"
            end

            display_off:
              timeout 300
              command "swaymsg 'output * power off'"
              resume_command "swaymsg 'output * power on'"
            end

            ac:
              lock_screen:
                timeout 1800
                command "swaylock"
              end

              display_off:
                timeout 300
                command "swaymsg 'output * power off'"
                resume_command "swaymsg 'output * power on'"
              end
            end

            battery:
              lock_screen:
                timeout 1800
                command "swaylock"
              end

              display_off:
                timeout 300
                command "swaymsg 'output * power off'"
                resume_command "swaymsg 'output * power on'"
              end
            end
          end
        '';
      };
      wayland.windowManager.sway = {
        enable = true;
        systemd.enable = false; # UWSM managed
        package = pkgs.unstable.swayfx;
        xwayland = true;
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
          input."type:pointer" = {
            natural_scroll = "disabled";
          };
          input."type:touchpad" = {
            accel_profile = "adaptive";
            click_method = "clickfinger";
            clickfinger_button_map = "lrm";
            dwt = "enabled";
            middle_emulation = "disabled";
            natural_scroll = "disabled";
            scroll_method = "two_finger";
            tap = "enabled";
            tap_button_map = "lrm";
          };
          input."type:keyboard" = {
            xkb_layout = nixosConfig.services.xserver.xkb.layout;
            xkb_options = nixosConfig.services.xserver.xkb.options;
          };
          workspaceAutoBackAndForth = true;
          window = {
            titlebar = false;
            border = 2;
            commands = [
              {
                criteria = {
                  app_id = "^$";
                  title = "^Authentication Required$";
                };
                command = "floating enable, resize set width 520 px height 260 px, move position center";
              }
            ];
          };
          floating.titlebar = false;
          focus.followMouse = false;
          keybindings = lib.mkOptionDefault {
            "${modifier}+b" = "exec ${browser}";
            "${modifier}+e" = "exec ${filemanager}";
            "${modifier}+Escape" = "exec ${lockScreen}";
            "${modifier}+Shift+s" = "exec ${screenshot}";
            "${modifier}+Return" = "exec ${terminal}";
            "${modifier}+d" = "exec ${menu}";
            "${modifier}+q" = "kill";
            "${modifier}+space" = "focus mode_toggle";
            "Print" = "exec ${screenshotScreen}";
            "Shift+Print" = "exec ${screenshotArea}";
            "Mod1+Print" = "exec ${screenshotWindow}";
            "XF86SelectiveScreenshot" = "exec ${screenshotArea}";
          };
        };
        extraConfig = ''
          bindgesture swipe:3:right workspace prev
          bindgesture swipe:3:left workspace next
          seat * hide_cursor when-typing enable
          blur enable
          default_dim_inactive 0.2
          exec uwsm finalize
        '';
      };

      home.packages = with pkgs; [
        wl-clipboard
        sway-contrib.grimshot
        xfce4-exo
        xfce4-settings
        autotiling
      ];

      home.sessionVariables.NIXOS_OZONE_WL = 1;

      xdg.configFile."xfce4/helpers.rc".text = ''
        [Helpers]
        TerminalEmulator=kitty
      '';

      xfconf.settings = {
        thunar = {
          "misc-volume-management" = true;
        };
        thunar-volman = {
          "automount-drives/enabled" = true;
          "automount-media/enabled" = true;
        };
      };

      xdg.configFile."uwsm/env".text = ''
        export XDG_SESSION_TYPE=wayland
        export NIXOS_OZONE_WL=1
        export ELECTRON_OZONE_PLATFORM_HINT=wayland
      '';

      home.activation.setThunarAsDefaultFileManager = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.xdg-utils}/bin/xdg-mime default thunar.desktop inode/directory
      '';

      services.gnome-keyring.enable = true;
      services.mako = {
        enable = true;
        settings = {
          default-timeout = 3000;
          ignore-timeout = true;
        };
      };
    };
}
