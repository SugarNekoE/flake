{ inputs, ... }:
{
  flake-file.inputs.disko.url = "github:nix-community/disko";

  imports = [ inputs.disko.flakeModules.default ];

  nixos = {
    imports = [ inputs.disko.nixosModules.disko ];
  };
}
