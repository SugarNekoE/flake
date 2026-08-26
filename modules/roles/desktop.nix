{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    _1password
    fcitx5
    fish
    zoxide
    fonts
    git
    gnupg
    kitty
    neovim
    singbox-gui
    starship
    unix-tools
    vicinae
    (flatpak.withPackages [
      "com.github.tchx84.Flatseal"
      "com.obsproject.Studio"
      "hu.irl.cameractrls"
      "io.github.flattool.Warehouse"
      "io.github.ilya_zlobintsev.LACT"
      "io.github.pwr_solaar.solaar"
      "io.missioncenter.MissionCenter"
      "net.agalwood.Motrix"
      "net.davidotek.pupgui2"
      "org.jellyfin.JellyfinDesktop"
      "org.localsend.localsend_app"
      "org.torproject.torbrowser-launcher"
      "org.videolan.VLC"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        google-chrome
        splayer
      ];
    };
}
