{ inputs, ... }:
{
  home = {
    imports = with inputs.self.aspects; [
      (flatpak.withPackages [
        "be.alexandervanhee.gradia"
        "com.mattjakeman.ExtensionManager"
        "com.sidevesh.Luminance"
        "io.github.realmazharhussain.GdmSettings"
        "org.gnome.Brasero"
        "org.gnome.NetworkDisplays"
        "org.gnome.SimpleScan"
      ])
    ];
  };
}
