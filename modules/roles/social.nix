{ inputs, ... }: {
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.teamspeak.TeamSpeak3"
      "com.QQ.qq"
      "com.tencent.WeChat"
    ])
  ];
  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      discord
      telegram-desktop
      fractal
    ];
  };
}
