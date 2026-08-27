{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    _1password
    fcitx5
    fish
    fonts
    git
    gnupg
    kitty
    netbird-app
    neovim
    starship
    unix-tools
    vicinae
    (flatpak.withPackages [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      "net.davidotek.pupgui2"
      "net.agalwood.Motrix"
      "org.jellyfin.JellyfinDesktop"
      "org.localsend.localsend_app"
      "io.gitlab.adhami3310.Impression"
    ])
  ];

  nixos.programs.dconf.enable = true;

  home =
    { pkgs, ... }:
    {
      stylix.targets = {
        gtk.enable = true;
        qt.enable = true;
      };

      gtk.colorScheme = "dark";

      home.packages = with pkgs; [
        google-chrome
        splayer
        mpv
        obs-studio
        cameractrls
        lact
        mission-center
        tor-browser
        vlc
        bilibili
      ];
    };
}
