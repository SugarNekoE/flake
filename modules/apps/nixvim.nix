{ inputs, ... }:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim/nixos-26.05";

  home = {
    imports = [ inputs.nixvim.homeModules.nixvim ];
  };
}
