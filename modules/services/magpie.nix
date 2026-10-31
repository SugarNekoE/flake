{
  flake-file.inputs.magpie.url = "git+https://forge.asnk.io/sugar/magpie";

  nixos =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.magpie.nixosModules.default ];

      services.magpie = {
        enable = true;
        package = inputs.magpie.packages.${pkgs.stdenv.hostPlatform.system}.magpie-cli;
        listenAddress = "0.0.0.0:3430";
      };
    };
}
