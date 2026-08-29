{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    hmcl
    (flatpak.withPackages [
      "com.valvesoftware.Steam"
      "com.vysp3r.ProtonPlus"
      "io.github.Foldex.AdwSteamGtk"
      "net.lutris.Lutris"
      "moe.launcher.the-honkers-railway-launcher"
      "sh.ppy.osu"
    ])
  ];
}
