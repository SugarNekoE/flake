{ inputs, ... }:
{
  flake-file.inputs.stasis = {
    url = "github:saltnpepper97/stasis";
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  home =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.stasis.homeModules.stasis ];

      services.stasis = {
        enable = true;
        target = "graphical-session.target";
        tray.enable = true;
        environmentFile = null;
        extraPathPackages = [
          config.programs.swaylock.package
          pkgs.sway
        ];
        extraConfig = ''
          @author "sugar"
          @description "Sway idle management"

          default:
            enable_loginctl_integration true
            enable_dbus_inhibit true
            prepare_sleep_command "swaylock"
            monitor_media true
            ignore_remote_media true
            notify_on_unpause true

            ac:
              lock_and_dpms:
                timeout 1800
                command "swaylock; swaymsg 'output * power off'"
                resume_command "swaymsg 'output * power on'"
              end
            end

            battery:
              lock_and_dpms:
                timeout 1800
                command "swaylock; swaymsg 'output * power off'"
                resume_command "swaymsg 'output * power on'"
              end
            end
          end
        '';
      };
    };
}
