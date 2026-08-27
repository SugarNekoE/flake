_: {
  nixos =
    { config, lib, ... }:
    {
      security.pam.services.swaylock = {
        fprintAuth = config.services.fprintd.enable;
      }
      // lib.optionalAttrs config.services.fprintd.enable {
        # Check a submitted password before waiting for the fingerprint reader.
        rules.auth.fprintd.order = config.security.pam.services.swaylock.rules.auth.unix.order + 10;
      };
    };

  home =
    {
      nixosConfig,
      pkgs,
      ...
    }:
    {
      stylix.targets.swaylock.enable = true;

      programs.swaylock = {
        enable = true;
        package = pkgs.swaylock-effects;
        settings = {
          clock = true;
          daemonize = true;
          datestr = "%A, %B %e";
          effect-blur = "12x4";
          effect-vignette = "0.2:0.5";
          fade-in = 0.25;
          font = nixosConfig.stylix.fonts.sansSerif.name;
          font-size = 28;
          ignore-empty-password = !nixosConfig.services.fprintd.enable;
          indicator = true;
          indicator-idle-visible = true;
          indicator-radius = 110;
          indicator-thickness = 8;
          show-failed-attempts = true;
          timestr = "%H:%M";
        };
      };
    };
}
