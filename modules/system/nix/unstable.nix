{ inputs, ... }:
{
  flake-file.inputs.nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

  nixos = {
    nixpkgs.overlays = [
      (_final: stable: {
        unstable = import inputs.nixpkgs-unstable {
          system = stable.stdenv.hostPlatform.system;
          inherit (stable) config;
        };
      })
    ];
  };
}
