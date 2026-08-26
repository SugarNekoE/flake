{ inputs, lib, ... }:
let
  withPackages =
    packages:
    {
      _class = "aspects";
    }
    // lib.optionalAttrs (packages != [ ]) {
      imports = [ inputs.self.modules.aspects.flatpak ];
      homeModule.services.flatpak.packages = packages;
    };
in
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  aspectHelpers.flatpak = { inherit withPackages; };

  nixos =
    { pkgs, ... }:
    {
      services.flatpak.enable = true;

      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
        config.common = {
          default = [ "gtk" ];
          "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
        };
      };
    };

  home = {
    imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

    services.flatpak.enable = true;
  };
}
