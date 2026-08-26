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

    (flatpak.withPackages [
      "io.github.kolunmi.Bazaar"
      "org.telegram.desktop"
      "org.localsend.localsend_app"
      "io.missioncenter.MissionCenter"
      "io.github.pwr_solaar.solaar"
      "com.qq.QQ"
      "com.tencent.WeChat"
      "com.tencent.wemeet"
      "com.slack.Slack"
    ])
  ];
}
