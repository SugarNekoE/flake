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
  };

  flake.modules.nixos.sugar =
    { user, ... }:
    {
      users.users.${user.username} = {
        isNormalUser = true;
        description = user.fullName;
        extraGroups = [ "wheel" ];
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${user.username} = { };
      };
    };

  flake.modules.homeManager.sugar =
    { user, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      home = {
        username = user.username;
        homeDirectory = "/home/${user.username}";
        stateVersion = "26.05";
      };

      programs.home-manager.enable = true;
    };
}
