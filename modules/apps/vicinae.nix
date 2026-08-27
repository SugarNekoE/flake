_: {
  home =
    {
      config,
      lib,
      nixosConfig,
      pkgs,
      ...
    }:
    {
      stylix.targets.vicinae.enable = true;

      programs.vicinae = {
        enable = true;
        settings = lib.mkIf nixosConfig.programs.uwsm.enable {
          providers.applications.preferences.launchPrefix = "uwsm-app --";
        };
        systemd = {
          enable = true;
          autoStart = true;
        };
      };

      systemd.user.services.vicinae.Service = {
        Environment = [ "QT_QPA_PLATFORM=wayland;xcb" ];
        KillMode = lib.mkForce "control-group";
      };

      home.activation.vicinae-refresh-apps = lib.mkForce (
        lib.hm.dag.entryAfter [ "installPackages" ] ''
          verboseEcho "Refreshing the vicinae app list"
          run --silence ${lib.getExe' pkgs.coreutils "timeout"} --foreground 5s \
            ${lib.getExe config.programs.vicinae.package} deeplink vicinae://launch/core/refresh-apps \
            || verboseEcho "Failed to refresh the vicinae app list"
        ''
      );
    };
}
