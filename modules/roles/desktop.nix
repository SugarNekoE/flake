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
      "org.gnome.Brasero"
      "org.gnome.NetworkDisplays"
      "io.missioncenter.MissionCenter"
      "io.github.ilya_zlobintsev.LACT"
      "hu.irl.cameractrls"
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

      stylix.targets.mpv.enable = true;

      home.packages = with pkgs; [
        mpv
        ffmpeg
        google-chrome
        tor-browser
        splayer
        obs-studio
        vlc
      ];
    };
}
