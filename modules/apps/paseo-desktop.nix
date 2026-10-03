{ inputs, ... }:
{
  flake-file.inputs.paseo.url = "git+https://forge.asnk.io/sugar/paseo";

  nixos = {
    nix.settings = {
      extra-substituters = [ "https://paseo.cachix.org" ];
      extra-trusted-public-keys = [
        "paseo.cachix.org-1:h14pJUWHBazoOx4Ztf8hnzU1ozk9/+Z27E01Isp65rg="
      ];
    };
  };

  home =
    { pkgs, ... }:
    let
      paseo = inputs.paseo.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [
        paseo.paseo-desktop
        paseo.paseo-daemon
      ];
    };
}
