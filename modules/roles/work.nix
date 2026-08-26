{ inputs, ... }:

{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "cn.feishu.Feishu"
      "com.slack.Slack"
      "com.tencent.wemeet"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        figma-linux
      ];
    };
}
