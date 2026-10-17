_: {
  nixos = {
    nixpkgs.overlays = [
      (final: prev: {
        sdrplay = prev.sdrplay.overrideAttrs (old: rec {
          version = "3.15.2";

          src = final.fetchurl {
            url = "https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-${version}.run";
            hash = "sha256-OpfKdkJju+dvsPIiDmQIlCNX6IZMGeFAim1ph684L+M=";
          };

          installPhase =
            builtins.replaceStrings [ "x86_64/" "aarch64/" ] [ "amd64/" "arm64/" ]
              old.installPhase;
        });
      })
    ];
    services.sdrplayApi.enable = true;
  };
  home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        (sdrpp.override {
          sdrplay_source = true;
        })
      ];
    };
}
