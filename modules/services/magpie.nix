{
  flake-file.inputs.magpie.url = "git+https://forge.asnk.io/sugar/magpie";

  nixos =
    { inputs, pkgs, ... }:
    {
      imports = [ inputs.magpie.nixosModules.default ];
      nix.settings = {
        extra-substituters = [ "https://magpie.cachix.org" ];
        extra-trusted-public-keys = [
          "magpie.cachix.org-1:ITAJciUQeU2SXzGFZvLXLMguTs0Uu9pYjT76gLmW4gs="
        ];
      };

      services.magpie = {
        enable = true;
        package = inputs.magpie.packages.${pkgs.stdenv.hostPlatform.system}.magpie-cli;
        listenAddress = "0.0.0.0:3430";
      };
    };
}
