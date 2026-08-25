{ inputs, ... }:
{
  flake-file.inputs.sops-nix.url = "github:Mic92/sops-nix";

  nixos = {
    imports = [ inputs.sops-nix.nixosModules.sops ];
  };

  home = {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];
  };
}
