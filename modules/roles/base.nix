{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    nix
    secrets
  ];

  nixos = {
    system.stateVersion = "26.05";
  };
}
