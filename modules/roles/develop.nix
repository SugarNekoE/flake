{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    agents
    zed
    (flatpak.withPackages [
      "com.redis.RedisInsight"
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
