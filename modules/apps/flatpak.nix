{ inputs, ... }:
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  home = {
    imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
  };
}
