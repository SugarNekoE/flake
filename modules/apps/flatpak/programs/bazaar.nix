{ inputs, ... }:
{
  flake.modules.aspects.bazaar.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "io.github.kolunmi.Bazaar" ];
}
