{ inputs, ... }:
{
  machines.laptop = {
    system = "x86_64-linux";
    imports = with inputs.self.modules.aspects; [
      base
      laptop
    ];
    hardware = import ../../hardware/laptop.nix;
  };
}
