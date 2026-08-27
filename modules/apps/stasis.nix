{ inputs, ... }:
{
  flake-file.inputs.stasis = {
    url = "github:saltnpepper97/stasis";
    inputs = {
      flake-parts.follows = "flake-parts";
      nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  home = {
    imports = [ inputs.stasis.homeModules.stasis ];

    services.stasis = {
      enable = true;
      target = "graphical-session.target";
      tray.enable = true;
      environmentFile = null;
    };
  };
}
