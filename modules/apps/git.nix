{
  nixos = {
    programs.git.enable = true;
  };
  home =
    {
      identity,
      pkgs,
      user,
      ...
    }:
    {
      home.packages = with pkgs; [
        git-lfs
      ];

      programs.git = {
        enable = true;
        settings = {
          user = {
            name = user.fullName;
            email = user.email;
            signingKey = identity.gpgKeys.main;
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
          commit.gpgsign = true;
          tag.gpgsign = true;
          gpg.program = "gpg";
          init.defaultBranch = "main";
          color.ui = "auto";
          credential.helper = "store";
        };
      };
    };
}
