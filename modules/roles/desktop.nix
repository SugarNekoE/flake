{ inputs, ... }:
{
  flake.modules.aspects.desktop.imports = with inputs.self.aspects; [
    secrets.home
    gnupg
    git
    zed
    slack
    bazaar
    telegram
    localsend
    mission-center
    solaar
    qq
    wechat
    wemeet
    singbox-gui
  ];
}
