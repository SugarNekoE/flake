_: {
  nixos.services.acpid.enable = true;

  home =
    {
      lib,
      pkgs,
      ...
    }:
    let
      swayosdClient = lib.getExe' pkgs.swayosd "swayosd-client";
      lockSession = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
      microphoneControl = pkgs.writeShellApplication {
        name = "microphone-control";
        runtimeInputs = with pkgs; [
          brightnessctl
          coreutils
          swayosd
          util-linux
          wireplumber
        ];
        text = ''
          action="''${1:-}"

          if [[ "$action" == "mute" ]]; then
            exec 9>"$XDG_RUNTIME_DIR/microphone-control.lock"
            flock --nonblock 9 || exit 0
          fi

          case "$action" in
            mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
            raise) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SOURCE@ 5%+ ;;
            lower) wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 5%- ;;
            *)
              echo "Usage: microphone-control {mute|raise|lower}" >&2
              exit 2
              ;;
          esac

          state="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@)"
          if [[ "$state" == *"[MUTED]"* ]]; then
            brightnessctl --quiet --device="platform::micmute" set 1 || true
          else
            brightnessctl --quiet --device="platform::micmute" set 0 || true
          fi

          swayosd-client --input-volume +0

          if [[ "$action" == "mute" ]]; then
            sleep 1.5
          fi
        '';
      };
      cycleKeyboardBacklight = pkgs.writeShellApplication {
        name = "cycle-keyboard-backlight";
        runtimeInputs = with pkgs; [
          brightnessctl
          swayosd
        ];
        text = ''
          device="tpacpi::kbd_backlight"
          current="$(brightnessctl --device="$device" get)"
          maximum="$(brightnessctl --device="$device" max)"
          next=$(( (current + 1) % (maximum + 1) ))

          brightnessctl --device="$device" set "$next"
          swayosd-client \
            --custom-icon keyboard-brightness-symbolic \
            --custom-segmented-progress "$next:$maximum"
        '';
      };
      cyclePowerProfile = pkgs.writeShellApplication {
        name = "cycle-power-profile";
        runtimeInputs = [ pkgs.power-profiles-daemon ];
        text = ''
          current="$(powerprofilesctl get)"
          case "$current" in
            power-saver) next="balanced" ;;
            balanced) next="performance" ;;
            performance) next="power-saver" ;;
            *) next="balanced" ;;
          esac

          powerprofilesctl set "$next"
        '';
      };
      showPowerProfile = pkgs.writeShellApplication {
        name = "show-power-profile";
        runtimeInputs = with pkgs; [
          libnotify
          power-profiles-daemon
          swayosd
        ];
        text = ''
          profile="''${1:-$(powerprofilesctl get)}"
          case "$profile" in
            power-saver) label="Power saver" ;;
            balanced) label="Balanced" ;;
            performance) label="Performance" ;;
            *) label="$profile" ;;
          esac

          swayosd-client \
            --custom-icon preferences-system-power-symbolic \
            --custom-message "Power mode: $label"
          notify-send \
            --app-name="Power mode" \
            --icon=preferences-system-power-symbolic \
            --expire-time=2500 \
            --hint=string:x-canonical-private-synchronous:power-profile \
            "Power mode" "$label"
        '';
      };
      monitorPowerProfile = pkgs.writeShellApplication {
        name = "monitor-power-profile";
        runtimeInputs = [ pkgs.power-profiles-daemon ];
        text = ''
          last="$(powerprofilesctl get)"

          ${lib.getExe' pkgs.glib.bin "gdbus"} monitor \
            --system \
            --dest net.hadess.PowerProfiles \
            --object-path /net/hadess/PowerProfiles \
            | while IFS= read -r event; do
                [[ "$event" == *"ActiveProfile"* ]] || continue

                current="$(powerprofilesctl get)"
                if [[ "$current" != "$last" ]]; then
                  last="$current"
                  ${lib.getExe showPowerProfile} "$current"
                fi
              done
        '';
      };
      toggleAirplaneMode = pkgs.writeShellApplication {
        name = "toggle-airplane-mode";
        runtimeInputs = with pkgs; [
          bluez
          networkmanager
          swayosd
        ];
        text = ''
          if [[ "$(nmcli --terse --fields WIFI radio)" == "enabled" ]]; then
            nmcli radio all off
            bluetoothctl power off >/dev/null || true
            message="Airplane mode on"
          else
            nmcli radio all on
            bluetoothctl power on >/dev/null || true
            message="Airplane mode off"
          fi

          swayosd-client \
            --custom-icon airplane-mode-symbolic \
            --custom-message "$message"
        '';
      };
      toggleTouchpad = pkgs.writeShellApplication {
        name = "toggle-touchpad";
        runtimeInputs = with pkgs; [
          jq
          swayosd
          unstable.swayfx
        ];
        text = ''
          current="$(swaymsg -t get_inputs | jq -r '[.[] | select(.type == "touchpad")][0].libinput.send_events')"
          swaymsg input type:touchpad events toggle >/dev/null

          if [[ "$current" == "enabled" ]]; then
            message="Touchpad disabled"
          else
            message="Touchpad enabled"
          fi

          swayosd-client \
            --custom-icon input-touchpad-symbolic \
            --custom-message "$message"
        '';
      };
    in
    {
      services.swayosd = {
        enable = true;
        topMargin = 0.85;
      };

      systemd.user.services.power-profile-notifier = {
        Unit = {
          Description = "Show ThinkPad power profile changes";
          After = [
            "sway-session.target"
            "swayosd.service"
          ];
          PartOf = [ "sway-session.target" ];
        };

        Service = {
          ExecStart = lib.getExe monitorPowerProfile;
          Restart = "always";
          RestartSec = "2s";
        };

        Install.WantedBy = [ "sway-session.target" ];
      };

      wayland.windowManager.sway.config.keybindings = lib.mkOptionDefault {
        "--locked XF86AudioRaiseVolume" = "exec ${swayosdClient} --output-volume +5 --max-volume 100";
        "--locked XF86AudioLowerVolume" = "exec ${swayosdClient} --output-volume -5";
        "--locked XF86AudioMute" = "exec ${swayosdClient} --output-volume mute-toggle";
        "--locked --no-repeat XF86AudioMicMute" = "exec ${lib.getExe microphoneControl} mute";
        "--locked Shift+XF86AudioRaiseVolume" = "exec ${lib.getExe microphoneControl} raise";
        "--locked Shift+XF86AudioLowerVolume" = "exec ${lib.getExe microphoneControl} lower";
        "--locked XF86MonBrightnessUp" = "exec ${swayosdClient} --brightness +5";
        "--locked XF86MonBrightnessDown" = "exec ${swayosdClient} --brightness -5";
        "--locked XF86KbdBrightnessUp" =
          "exec ${swayosdClient} --device tpacpi::kbd_backlight --brightness raise";
        "--locked XF86KbdBrightnessDown" =
          "exec ${swayosdClient} --device tpacpi::kbd_backlight --brightness lower";
        "--locked XF86KbdLightOnOff" = "exec ${lib.getExe cycleKeyboardBacklight}";
        "--locked XF86AudioPlay" = "exec ${swayosdClient} --playerctl play-pause";
        "--locked XF86AudioPause" = "exec ${swayosdClient} --playerctl play-pause";
        "--locked XF86AudioNext" = "exec ${swayosdClient} --playerctl next";
        "--locked XF86AudioPrev" = "exec ${swayosdClient} --playerctl prev";
        "--locked XF86AudioStop" = "exec ${swayosdClient} --playerctl stop";
        "XF86Display" = "exec wdisplays";
        "--locked --no-repeat XF86PerformanceMode" = "exec ${lib.getExe cyclePowerProfile}";
        "--locked --no-repeat XF86Battery" = "exec ${lib.getExe cyclePowerProfile}";
        "XF86TouchpadToggle" = "exec ${lib.getExe toggleTouchpad}";
        "XF86WLAN" = "exec ${lib.getExe toggleAirplaneMode}";
        "XF86RFKill" = "exec ${lib.getExe toggleAirplaneMode}";
        "XF86ScreenSaver" = "exec ${lockSession}";
      };

      home.packages = with pkgs; [
        brightnessctl
        playerctl
        wdisplays
      ];
    };
}
