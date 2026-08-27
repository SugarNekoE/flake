_: {
  home =
    { lib, pkgs, ... }:
    {
      systemd.user.services.pasystray = {
        Unit = {
          Description = "PulseAudio system tray";
          After = [
            "graphical-session.target"
            "pipewire-pulse.service"
          ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = lib.getExe pkgs.pasystray;
          Restart = "on-failure";
          RestartSec = "2s";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
