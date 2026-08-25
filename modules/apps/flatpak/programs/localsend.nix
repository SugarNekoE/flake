{ inputs, ... }:
{
  flake.modules.aspects.localsend.imports = [ inputs.self.modules.aspects.flatpak ];
  home.services.flatpak.packages = [ "org.localsend.localsend_app" ];
}
