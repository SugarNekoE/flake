{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.tencent.WeChat"
      "com.qq.QQ"
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "com.teamspeak.TeamSpeak3"
      "org.gnome.Fractal"
    ])
  ];
}
