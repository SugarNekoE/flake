{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    agents
    zed
    podman
    (flatpak.withPackages [
      "com.redis.RedisInsight"
    ])
  ];
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        b4
        lens
        winbox
        blender
        terraform
        jetbrains.idea
        unstable.xpipe
        android-tools
        android-studio
        podman-desktop
        jetbrains.datagrip
        jetbrains.gateway
        apache-directory-studio
      ];
    };
}
