{ inputs, ... }:
{
  flake.modules.aspects.solaar.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "io.github.pwr_solaar.solaar" ];
}
