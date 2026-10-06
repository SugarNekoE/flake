{ inputs, ... }:
{
  flake-file.inputs.paseo.url = "git+https://forge.asnk.io/sugar/paseo";

  nixos.nix.settings = {
    extra-substituters = [ "https://paseo.cachix.org" ];
    extra-trusted-public-keys = [
      "paseo.cachix.org-1:3rnoaYFr84a5XMqcq15I7PClk6ePc2lvECHq4gpERAg="
    ];
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
