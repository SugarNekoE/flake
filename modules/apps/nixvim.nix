{ inputs, ... }:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim/nixos-26.05";

  flake.modules.homeManager.nixvim = {
    imports = [ inputs.nixvim.homeModules.nixvim ];
  };
}
