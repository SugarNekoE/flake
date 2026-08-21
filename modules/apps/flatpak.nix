{ inputs, ... }:
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  flake.modules.homeManager.flatpak = {
    imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  };
}
