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
    { config, user, ... }:
    {
      imports = [ inputs.self.modules.nixos.users ];

      sops.secrets.nix-auth = {
        sopsFile = ../secrets/nix-auth.yaml;
        key = "nix-auth";
        owner = user.username;
        mode = "0400";
      };

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
        users.${user.username} = {
          nix.extraOptions = ''
            !include ${config.sops.secrets.nix-auth.path}
          '';

          xdg.userDirs = {
            enable = true;
            createDirectories = true;
            projects = null;
          };
        };
      };
    };

  darwin =
    { user, ... }:
    {
      system.primaryUser = user.username;

      users.users.${user.username} = {
        description = user.fullName;
        home = "/Users/${user.username}";
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
        sessionVariables = {
          LANG = "en_US.UTF-8";
          LANGUAGE = "en_US.UTF-8";
        };
        stateVersion = "26.05";
      };

      programs.home-manager.enable = true;
    };
}
