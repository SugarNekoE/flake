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

  nixos.programs.dconf.enable = true;

  home =
    { pkgs, ... }:
    {
      gtk = {
        enable = true;
        colorScheme = "dark";
      };

      qt = {
        enable = true;
        platformTheme.name = "adwaita";
        style.name = "adwaita-dark";
      };

      home.packages = with pkgs; [
        btop
        htop
        google-chrome
        splayer
      ];
    };
}
