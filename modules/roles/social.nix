{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.teamspeak.TeamSpeak3"
      "com.qq.QQ"
      "com.tencent.WeChat"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        discord
        unstable.telegram-desktop
        fractal
      ];
    };
}
