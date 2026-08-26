{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    codex
    zed
    (flatpak.withPackages [
      "cn.lceda.LCEDAPro"
      "com.apifox.Apifox"
      "com.mikrotik.WinBox"
      "com.redis.RedisInsight"
      "io.podman_desktop.PodmanDesktop"
      "org.apache.directory.studio"
      "org.blender.Blender"
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
      ];
    };
}
