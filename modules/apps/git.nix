_: {
  nixos = {
    programs.git.enable = true;
  };
  home =
    {
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
