{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.teamspeak.TeamSpeak3"
      "com.discordapp.Discord"
      "org.telegram.desktop"
      "in.cinny.Cinny"
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
