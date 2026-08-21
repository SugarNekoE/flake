{ inputs, ... }:
{
  flake.modules.aspects.base.imports = with inputs.self.modules.aspects; [
    nix
    disko
    secrets
  ];

  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    system.stateVersion = "26.05";
  };
}
