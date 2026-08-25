{ inputs, ... }:
{
  flake.modules.aspects.telegram.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "org.telegram.desktop" ];
}
