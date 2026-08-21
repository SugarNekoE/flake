{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  flake.modules.homeManager.index-database = {
    imports = [ inputs.nix-index-database.homeModules.nix-index ];
  };
}
