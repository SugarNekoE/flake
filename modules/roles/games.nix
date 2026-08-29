{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.valvesoftware.Steam"
      "com.vysp3r.ProtonPlus"
      "io.github.Foldex.AdwSteamGtk"
      "net.lutris.Lutris"
      "moe.launcher.the-honkers-railway-launcher"
      "sh.ppy.osu"
    ])
  ];
  home =
    { pkgs, ... }:
    let
      hmcl = pkgs.hmcl.overrideAttrs (oldAttrs: {
        postFixup = oldAttrs.postFixup + ''
          wrapProgram $out/bin/hmcl --set HMCL_FONT "Noto Sans CJK SC"
        '';
      });
    in
    {
      home.packages = [ hmcl ];
    };
}
