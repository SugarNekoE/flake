{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    darwin
    unstable
  ];

  darwin.system.stateVersion = 7;
}
