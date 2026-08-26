{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    codex
    zed
    (flatpak.withPackages [
      "com.redisinsight.RedisInsight"
    ])
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
        podman-desktop
        apache-directory-studio
        blender
      ];
    };
}
