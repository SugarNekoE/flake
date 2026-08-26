_:
let
  largeIcon = icon: "<span size='140%'>${icon}</span>";
in
{
  home = {
    stylix.targets.waybar = {
      enable = true;
      addCss = false;
      opacity.enable = false;
    };

    services.playerctld.enable = true;

    programs.waybar = {
      enable = true;
      systemd.enable = true;

      settings = [
        {
          name = "topbar";
          layer = "overlay";
          position = "top";
          margin-top = 0;
          exclusive = true;
          passthrough = false;
          height = 34;
          spacing = 4;
          modules-left = [
            "clock"
            "custom/hostname"
          ];
          modules-center = [ "mpris" ];
          modules-right = [
            "network#speed"
            "cpu"
            "memory"
            "battery"
            "backlight"
            "tray"
          ];

          clock = {
            format = "{:%H:%M}";
            tooltip-format = "{:%Y-%m-%d}";
          };

          "custom/hostname" = {
            exec = "hostname";
            interval = "once";
            tooltip = false;
          };

          systemd-failed-units = {
            hide-on-ok = true;
            format = "${largeIcon ""} {nr_failed}";
            format-ok = largeIcon "";
            system = true;
            user = true;
          };

          backlight = {
            format = "${largeIcon "{icon}"} {percent}%";
            format-icons = [
              "󰃞"
              "󰃝"
              "󰃠"
            ];
            on-scroll-up = "brightnessctl set 1%+";
            on-scroll-down = "brightnessctl set 1%-";
            min-length = 6;
          };

          battery = {
            format = "${largeIcon "{icon}"} {capacity}%";
            format-charging = "${largeIcon ""} {capacity}%";
            format-plugged = "${largeIcon ""} {capacity}%";
            format-icons = [
              "󰂎"
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
          };

          cpu = {
            interval = 3;
            format = "${largeIcon ""} {}%";
          };

          memory = {
            interval = 3;
            format = "${largeIcon ""} {}%";
            tooltip = true;
            tooltip-format = "Memory - {used:0.1f}GB used";
            on-click = "kitty --start-as=fullscreen --title btop sh -c 'btop'";
          };

          "network#speed" = {
            interval = 3;
            format-wifi = "${largeIcon ""} {bandwidthUpBytes} ${largeIcon ""} {bandwidthDownBytes}";
            format-ethernet = "${largeIcon ""} {bandwidthUpBytes} ${largeIcon ""} {bandwidthDownBytes}";
          };

          tray = {
            icon-size = 18;
            spacing = 4;
          };
        }
        {
          name = "taskbar";
          layer = "top";
          position = "bottom";
          exclusive = true;
          passthrough = false;
          height = 30;
          spacing = 0;
          modules-left = [
            "sway/workspaces"
            "wlr/taskbar"
          ];
          "sway/workspaces" = {
            all-outputs = true;
            disable-scroll-wraparound = true;
            format = "{name}";
          };
          "wlr/taskbar" = {
            all-outputs = true;
            format = "{icon} {title}";
            icon-size = 20;
            icon-theme = "Tela-dark";
            tooltip = false;
            homogeneous = true;
            truncate = true;
            justify = "left";
            on-click = "activate";
            on-click-middle = "close";
          };
        }
      ];

      style = ''
        window#waybar.topbar {
          background: alpha(@base00, 0.92);
        }

        window#waybar.topbar > box {
          padding: 0 6px;
        }

        window#waybar.topbar .modules-left,
        window#waybar.topbar .modules-center,
        window#waybar.topbar .modules-right {
          min-height: 34px;
        }

        #clock,
        #custom-hostname,
        #mpris,
        #network,
        #cpu,
        #memory,
        #battery,
        #backlight,
        #tray {
          padding: 0 6px;
          margin: 0;
        }

        window#waybar.taskbar {
          background: alpha(@base00, 0.92);
          border-top: 1px solid alpha(@base04, 0.35);
        }

        #workspaces {
          background: @base01;
        }

        #workspaces button,
        #taskbar button {
          min-width: 32px;
          padding: 0 10px;
          color: @base04;
          background: transparent;
          border: 0;
          border-radius: 0;
          box-shadow: inset 0 -2px transparent;
          text-shadow: none;
        }

        #workspaces button:hover,
        #taskbar button:hover {
          padding: 0 10px;
          color: @base04;
          background: transparent;
          border: 0;
          box-shadow: inset 0 -2px transparent;
          text-shadow: none;
        }

        #workspaces button.focused,
        #taskbar button.active {
          color: @base07;
          background: @base02;
          box-shadow: inset 0 -2px @base0D;
        }

        #workspaces button.urgent,
        #taskbar button.urgent {
          color: @base00;
          background: @base08;
          box-shadow: inset 0 -2px @base0A;
        }
      '';
    };
  };
}
