{
  home =
    { pkgs, ... }:
    let
      splayer-next = pkgs.unstable.splayer-next.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = "1.2.0-nightly.904";

          src = oldAttrs.src.override {
            tag = null;
            rev = "ceb9d72b34fe4266674c814f2b3dcd46352a67e5";
            hash = "sha256-J2qpeWBB32NWjg5oNJ77djDM67MVPOZd8LERlg56B4E=";
          };

          pnpmDeps = oldAttrs.pnpmDeps.override {
            inherit (finalAttrs) version src;
            hash = "sha256-X2YhbuYe2+o62y/ECk7fsLDDHmbwIqJ1ZRkfYLPz2Ag=";
          };

          cargoDeps = pkgs.unstable.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = "sha256-9doP83tZlKM8Hsu+NHYOLLWq1RWFS+IGB2oOXwA4d2g=";
          };

          buildInputs = oldAttrs.buildInputs ++ [ pkgs.unstable.dbus ];

          postPatch = oldAttrs.postPatch + ''
            substituteInPlace package.json \
              --replace-fail '"version": "1.2.0-beta.1"' '"version": "${finalAttrs.version}"'
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
