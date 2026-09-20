{
  home =
    { pkgs, ... }:
    let
      splayer-next = pkgs.unstable.splayer-next.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = "1.2.0-nightly.872";

          # Pin the nightly release's commit because the nightly tag moves.
          src = oldAttrs.src.override {
            tag = null;
            rev = "d3dd84df99333f19b04a2faef1972a89f35aee0f";
            hash = "sha256-fAzce8yDPOoukK/T8TUKZ9OxFwE2YgPKXqjBAWygi8c=";
          };

          pnpmDeps = oldAttrs.pnpmDeps.override {
            inherit (finalAttrs) version src;
            hash = "sha256-wYQnp76oCjpirj5VOQKmPmXxkyraJAFcShUQK7cCXY0=";
          };

          postPatch = oldAttrs.postPatch + ''
            substituteInPlace package.json \
              --replace-fail '"version": "1.2.0-alpha.1"' '"version": "${finalAttrs.version}"'
          '';

          meta = oldAttrs.meta // {
            changelog = "https://github.com/SPlayer-Dev/SPlayer-Next/releases/tag/nightly";
          };
        }
      );
    in
    {
      home.packages = [ splayer-next ];
    };
}
