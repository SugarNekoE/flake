_: {
  nixos = {
    programs.git.enable = true;
  };
  home =
    {
      identity,
      lib,
      pkgs,
      user,
      ...
    }:
    let
      signingKey = identity.gpgKeys.${user.git.signingKey} or null;
    in
    {
      assertions = [
        {
          assertion = signingKey != null;
          message = "user `${user.username}` selects unknown GPG identity `${user.git.signingKey}`";
        }
      ];

      home.packages = with pkgs; [
        git-lfs
      ];

      programs.git = {
        enable = true;
        signing = lib.mkIf (signingKey != null) {
          key = signingKey.fingerprint;
          signByDefault = true;
          signer = lib.getExe pkgs.gnupg;
        };
        settings = {
          user = {
            name = user.fullName;
            email = user.email;
          };
          core = {
            editor = "nvim";
            autocrlf = "input";
            preloadindex = true;
            fscache = true;
          };
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
          init.defaultBranch = "main";
          color.ui = "auto";
          credential.helper = "store";
        };
      };
    };
}
