{ inputs, ... }:
{
  flake.modules.aspects.base.imports = with inputs.self.modules.aspects; [
    nix
    disko
    secrets
  ];

  nixos = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    system.stateVersion = "26.05";
  };
}
