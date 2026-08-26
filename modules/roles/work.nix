_: {
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        figma-linux
        wemeet
        slack
        feishu
      ];
    };
}
