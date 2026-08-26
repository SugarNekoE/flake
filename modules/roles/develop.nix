{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    codex
    zed
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        lens
        jetbrains.idea
        jetbrains.datagrip
        jetbrains.gateway
        android-tools
        android-studio
        winbox
        redisinsight
        podman-desktop
        apache-directory-studio
        blender
      ];
    };
}
