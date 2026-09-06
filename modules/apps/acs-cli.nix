{ inputs, ... }:
{
  flake-file.inputs.acs-k8s.url = "git+https://forge.asnk.io/sugar/acs-k8s";

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  nixos = {
    nix.settings = {
      extra-substituters = [ "https://ack-nix.cachix.org" ];
      extra-trusted-public-keys = [
        "acs-k8s.cachix.org-1:DWI0wISknATlw/wqfWvcNKqHS2ck9hjqAtysB/ZaQLQ="
      ];
    };
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.acs-k8s.packages.${pkgs.stdenv.hostPlatform.system}.acs
        pkgs.buildah
        pkgs.skopeo
      ];
    };
}
