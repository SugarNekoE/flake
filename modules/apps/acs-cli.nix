{ inputs, ... }:
{
  flake-file.inputs.acs-k8s.url = "git+https://forge.asnk.io/sugar/acs-k8s";

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
