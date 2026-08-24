_: {
  flake-file.inputs = {
    nix-index-database.url = "github:nix-community/nix-index-database";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
  };

  flake.modules.nixos.user = {
    users.users.user = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.user = { };
    };
  };
}
