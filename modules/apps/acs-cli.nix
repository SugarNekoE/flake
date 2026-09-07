{ inputs, ... }:
{
  flake-file.inputs.acs-k8s.url = "git+https://forge.asnk.io/sugar/acs-k8s";

  nixos = {
    nix.settings = {
      extra-substituters = [ "https://acs-nix.cachix.org" ];
      extra-trusted-public-keys = [
        "acs-k8s.cachix.org-1:DWI0wISknATlw/wqfWvcNKqHS2ck9hjqAtysB/ZaQLQ="
      ];
    };
  };

  home =
    { pkgs, ... }:
    let
      acs-cli = inputs.acs-k8s.packages.${pkgs.stdenv.hostPlatform.system}.acs-cli;
    in
    {
      home.packages = [
        acs-cli
        pkgs.buildah
        pkgs.skopeo
      ];
    };
}
