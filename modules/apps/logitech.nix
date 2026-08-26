_: {
  nixos.hardware.logitech.wireless.enable = true;

  home =
    {
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = [ pkgs.unstable.solaar ];

      systemd.user.services.solaar = {
        Unit = {
          Description = "Solaar Logitech wireless device manager";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe pkgs.unstable.solaar} --window=hide --battery-icons=symbolic --tray-icon-size=24";
          Restart = "on-failure";
          RestartSec = "2s";
        };

        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
}
