{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    nix
    unstable
    secrets
    openssh
  ];

  nixos = {
    system = {
      stateVersion = "26.05";
      configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
    };
  };
}
