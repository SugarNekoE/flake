{ inputs, ... }:
{
  flake.modules.aspects.laptop.imports = with inputs.self.modules.aspects; [
    unstable
    flatpak
    index-database
    nixvim
    user
  ];
}
