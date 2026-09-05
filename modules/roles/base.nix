{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    nix
    unstable
    secrets
    openssh
  ];

  nixos = {
    system.stateVersion = "26.05";
  };
}
