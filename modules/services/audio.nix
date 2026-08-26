_: {
  nixos = {
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    services.pulseaudio.enable = false;
  };

  home =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.pavucontrol ];

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
