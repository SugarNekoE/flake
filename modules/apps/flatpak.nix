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
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        packages = [ ];
        uninstallUnmanaged = true;
        uninstallUnused = true;
      };

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

  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      packageId = package: if builtins.isString package then package else package.appId;
      applicationIds = lib.unique (map packageId config.services.flatpak.packages);
      stylixConfigFiles = {
        "gtk-3.0/gtk.css" = config.xdg.configFile."gtk-3.0/gtk.css".source;
        "gtk-3.0/settings.ini" = config.xdg.configFile."gtk-3.0/settings.ini".source;
        "gtk-4.0/gtk.css" = config.xdg.configFile."gtk-4.0/gtk.css".source;
        "gtk-4.0/settings.ini" = config.xdg.configFile."gtk-4.0/settings.ini".source;
      };
      copyStylixConfig = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (relativePath: source: ''
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -Dm644 \
            ${lib.escapeShellArg (toString source)} \
            "$app_config/${relativePath}"
        '') stylixConfigFiles
      );
    in
    {
      imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

      home.activation.flatpakStylix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        for app_id in ${lib.concatMapStringsSep " " lib.escapeShellArg applicationIds}; do
          app_config=${lib.escapeShellArg config.home.homeDirectory}/.var/app/"$app_id"/config
          ${copyStylixConfig}
        done
      '';

      services.flatpak = {
        enable = true;
        uninstallUnmanaged = true;
        uninstallUnused = true;
        overrides.global = {
          Context.filesystems = [
            "xdg-data/icons:ro"
            "xdg-data/themes:ro"
          ];
          Environment = {
            XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
            XCURSOR_SIZE = toString config.home.pointerCursor.size;
            XCURSOR_THEME = config.home.pointerCursor.name;
          };
        };
      };
    };
}
