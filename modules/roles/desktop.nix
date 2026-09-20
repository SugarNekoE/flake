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
    splayer-next
    starship
    unix-tools
    (flatpak.withPackages [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      "net.davidotek.pupgui2"
      "net.agalwood.Motrix"
      "org.jellyfin.JellyfinDesktop"
      "org.localsend.localsend_app"
      "io.gitlab.adhami3310.Impression"
      "org.gnome.Brasero"
      "org.gnome.NetworkDisplays"
      "hu.irl.cameractrls"
      "org.videolan.VLC"
      "com.github.wwmm.easyeffects"
    ])
  ];

  home =
    { pkgs, ... }:
    {
      stylix.targets = {
        gtk.enable = true;
        qt.enable = true;
      };

      gtk.colorScheme = "dark";

      stylix.targets.mpv.enable = true;

      home.packages = with pkgs; [
        mpv
        ffmpeg
        obs-studio
        tor-browser
        google-chrome
      ];
    };
}
