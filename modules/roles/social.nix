{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    halloy
    (flatpak.withPackages [
      "io.github.martinrotter.rssguard"
      "com.teamspeak.TeamSpeak3"
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "com.rtosta.zapzap"
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
