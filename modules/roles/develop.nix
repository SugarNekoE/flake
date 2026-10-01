{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    zed
    podman
    (flatpak.withPackages [
      "com.usebruno.Bruno"
      "com.redis.RedisInsight"
      "org.apache.directory.studio"
    ])
  ];
  nixos = {
    nixpkgs.config = {
      android_sdk.accept_license = true;
    };
  };
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        b4
        lens
        winbox
        blender
        terraform
        podman-desktop
        unstable.xpipe
        unstable.android-tools
        unstable.android-studio-full
        unstable.jetbrains.idea
        unstable.jetbrains.datagrip
        unstable.jetbrains.gateway
      ];
    };
}
