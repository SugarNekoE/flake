{ inputs, ... }: {
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.slack.Slack"
      "com.tencent.wemeet"
      "cn.feishu.Feishu"
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
