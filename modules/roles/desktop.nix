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
    stasis
    unix-tools
    vicinae
    (flatpak.withPackages [
      "com.github.tchx84.Flatseal"
      "io.github.flattool.Warehouse"
      "net.davidotek.pupgui2"
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
        obs-studio
        cameractrls
        lact
        mission-center
        motrix
        jellyfin-desktop
        localsend
        tor-browser
        vlc
      ];

      home.sessionVariables = {
        NIXOS_OZONE_WL = 1;
      };
    };
}
