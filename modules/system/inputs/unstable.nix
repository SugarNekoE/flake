{ inputs, ... }:
let
  unstableModule = {
    nixpkgs.overlays = [
      (_final: stable: {
        unstable = import inputs.nixpkgs-unstable {
          system = stable.stdenv.hostPlatform.system;
          inherit (stable) config;
        };
      })
    ];
  };
in
{
  flake-file.inputs.nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

  nixos = unstableModule;
  darwin = unstableModule;
}
