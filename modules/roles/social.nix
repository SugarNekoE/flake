{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.teamspeak.TeamSpeak3"
      "com.qq.QQ"
      "com.tencent.WeChat"
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "org.gnome.Fractal"
    ])
  ];
}
