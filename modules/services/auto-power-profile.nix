{ inputs, ... }:
{
  nixos =
    { lib, pkgs, ... }:
    let
      autoPowerProfile = pkgs.writeShellApplication {
        name = "auto-power-profile";
        runtimeInputs = with pkgs; [
          coreutils
          gawk
          power-profiles-daemon
          systemd
          upower
        ];
        text = ''
          export LC_ALL=C
          last_target=""

          update_profile() {
            local on_battery percentage target current
            on_battery="$(busctl --system get-property org.freedesktop.UPower \
              /org/freedesktop/UPower org.freedesktop.UPower OnBattery)"

            if [[ "$on_battery" == "b false" ]]; then
              target="performance"
            else
              percentage="$(busctl --system get-property org.freedesktop.UPower \
                /org/freedesktop/UPower/devices/DisplayDevice \
                org.freedesktop.UPower.Device Percentage)"
              target="$(awk '{ print ($2 < 20 ? "power-saver" : "balanced") }' <<< "$percentage")"
            fi

            if [[ "$target" != "$last_target" ]]; then
              current="$(powerprofilesctl get)"
              if [[ "$current" != "$target" ]]; then
                powerprofilesctl set "$target"
              fi
              last_target="$target"
            fi
          }

          stdbuf -oL upower --monitor | while IFS= read -r _event; do
            update_profile
          done
        '';
      };
    in
    {
      imports = [ inputs.self.modules.nixos.power ];

      systemd.services.auto-power-profile = {
        description = "Select the laptop power profile from AC and battery state";
        wantedBy = [ "graphical.target" ];
        wants = [
          "upower.service"
          "power-profiles-daemon.service"
        ];
        after = [
          "upower.service"
          "power-profiles-daemon.service"
        ];
        serviceConfig = {
          ExecStart = lib.getExe autoPowerProfile;
          Restart = "always";
          RestartSec = "2s";
        };
      };
    };
}
