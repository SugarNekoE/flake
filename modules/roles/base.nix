{ inputs, ... }:
{
  flake.modules.aspects.base.imports = with inputs.self.aspects; [
    nix
    secrets.nixos
  ];

  nixos = {
    system.stateVersion = "26.05";
  };
}
