{ inputs, ... }:
{
  flake-file.inputs = {
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    nix-index-database.url = "github:nix-community/nix-index-database";
  };

  userProfiles.sugar = {
    username = "sugar";
    fullName = "Asai Neko";
    email = "sugar@sne.moe";
    hashedPassword = "$y$j9T$6J6oW6wOgOw2.O.Il6qXA/$R2FgAePc0DR4dkeUcBIU0P/tPB/dSlD883Zr6LydxB.";
    git.signingKey = "main";
  };

  nixos =
    { user, ... }:
    {
      imports = [ inputs.self.modules.nixos.users ];

      users.users.${user.username} = {
        isNormalUser = true;
        description = user.fullName;
        inherit (user) hashedPassword;
        extraGroups = [
          "wheel"
          "video"
          "networkmanager"
          "input"
        ];
      };

      home-manager = {
        backupFileExtension = "backup";
        overwriteBackup = true;
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user.username} = { };
      };
    };

  home =
    { user, ... }:
    {
      home = {
        inherit (user) username;
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
