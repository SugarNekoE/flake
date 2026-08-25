{ inputs, ... }:
{
  flake-file = {
    inputs.nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";

    outputs = ''
      inputs:
        inputs.flake-parts.lib.mkFlake { inherit inputs; } ./modules/aspects.nix
    '';
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    inputs.flake-file.flakeModules.nix-auto-follow
  ];
}
