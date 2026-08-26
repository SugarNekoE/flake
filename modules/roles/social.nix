_: {
  home = { pkgs, ... }: {
    home.packages = with pkgs; [
      wechat
      qq
      discord
      telegram-desktop
      teamspeak3
      fractal
    ];
  };
}
