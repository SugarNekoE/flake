_: {
  home =
    { identity, pkgs, ... }:
    {
      home.packages = [ pkgs.b4 ];

      programs.git.settings = {
        b4.send-endpoint-web = "https://lkml.kernel.org/_b4_submit";
        user.signingKey = identity.gpgKeys.main.fingerprint;
      };
    };
}
