{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    _1password
    codex
    fcitx5
    fish
    git
    gnupg
    kitty
    neovim
    singbox-gui
    starship
    unix-tools
    vicinae
    zed

    # flatpak
    bazaar
    telegram
    localsend
    mission-center
    solaar
    qq
    wechat
    wemeet
    slack
  ];
}
