{ inputs, ... }:
{
  imports = with inputs.self.aspects; [
    zed
    podman
    (flatpak.withPackages [
      "com.usebruno.Bruno"
      "com.termius.Termius"
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
        terraform
        podman-desktop
        unstable.android-tools
        unstable.android-studio-full
        unstable.jetbrains.idea
        unstable.jetbrains.datagrip
        unstable.jetbrains.gateway
        (unstable.blender.override {
          config.cudaSupport = true;
          config.rocmSupport = true;
        })
      ];
    };
}
