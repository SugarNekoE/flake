{ inputs, ... }:
{
  flake-file.inputs.paseo.url = "git+https://forge.asnk.io/sugar/paseo";

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
