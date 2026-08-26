{ inputs, ... }: {
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.teamspeak.TeamSpeak3"
    ])
  ];
  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      wechat
      qq
      discord
      telegram-desktop
      fractal
    ];
  };
}
