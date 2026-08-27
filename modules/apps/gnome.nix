{ inputs, ... }:
let
  packages = [
    "be.alexandervanhee.gradia"
    "com.mattjakeman.ExtensionManager"
    "com.sidevesh.Luminance"
    "io.github.realmazharhussain.GdmSettings"
    "org.gnome.Brasero"
    "org.gnome.NetworkDisplays"
    "org.gnome.SimpleScan"
  ];
in
{
  nixos.imports = [ inputs.self.modules.nixos.flatpak ];

  home = {
    imports = [ inputs.self.modules.homeManager.flatpak ];
    services.flatpak.packages = packages;
  };
}
