_: {
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        figma-linux
        slack
        feishu
        unstable.wemeet
      ];
    };
}
