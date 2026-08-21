_: {
  flake.modules.homeManager.user = {
    home = {
      username = "user";
      homeDirectory = "/home/user";
      stateVersion = "26.05";
    };

    programs.home-manager.enable = true;
  };
}
