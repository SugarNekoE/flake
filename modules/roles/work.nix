{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    (flatpak.withPackages [
      "com.slack.Slack"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        figma-linux
        unstable.wemeet
        feishu
      ];
    };
}
