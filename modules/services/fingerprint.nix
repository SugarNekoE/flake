_: {
  nixos =
    { config, ... }:
    {
      services.fprintd.enable = true;
      security.pam.services.swaylock = {
        fprintAuth = true;

        # Check a submitted password before waiting for the fingerprint reader.
        rules.auth.fprintd.order = config.security.pam.services.swaylock.rules.auth.unix.order + 10;
      };
    };

  home =
    { lib, ... }:
    {
      # Let an empty Enter press start PAM fingerprint authentication.
      programs.swaylock.settings.ignore-empty-password = lib.mkForce false;
    };
}
