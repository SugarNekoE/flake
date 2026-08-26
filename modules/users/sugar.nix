_: {
  flake-file.inputs = {
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nix-index-database.url = "github:nix-community/nix-index-database";
  };

  userProfiles.sugar = {
    username = "sugar";
    fullName = "Asai Neko";
    email = "sugar@sne.moe";
  };

  nixos =
    { user, ... }:
    {
      users.users.${user.username} = {
        isNormalUser = true;
        description = user.fullName;
        extraGroups = [
          "wheel"
          "video"
          "networkmanager"
          "input"
        ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user.username} = { };
      };
    };

  home =
    { user, ... }:
    {
      home = {
        username = user.username;
        homeDirectory = "/home/${user.username}";
        sessionVariables = {
          LANG = "en_US.UTF-8";
          LANGUAGE = "en_US.UTF-8";
        };
        stateVersion = "26.05";
      };

      xdg.userDirs = {
        enable = true;
        createDirectories = true;
      };

      programs.home-manager.enable = true;
    };
}
