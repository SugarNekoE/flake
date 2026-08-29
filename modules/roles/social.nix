{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "io.github.martinrotter.rssguard"
      "com.teamspeak.TeamSpeak3"
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "org.gnome.Fractal"
    ])
  ];

  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs.unstable; [
        qq
        wechat
      ];
    };
}
