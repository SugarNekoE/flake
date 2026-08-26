{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    nix
    unstable
    secrets
  ];

  nixos = {
    system.stateVersion = "26.05";
  };
}
