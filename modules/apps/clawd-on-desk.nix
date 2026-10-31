{ inputs, ... }:
{
  flake-file.inputs.clawd-on-desk = {
    url = "git+https://forge.asnk.io/sugar/clawd-on-desk";
  };

  home =
    { pkgs, ... }:
    {
      home.packages = [
        inputs.clawd-on-desk.packages.${pkgs.stdenv.hostPlatform.system}.clawd-on-desk
      ];
    };
}
