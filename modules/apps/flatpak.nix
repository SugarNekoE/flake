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

  home =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      installPackage =
        package:
        let
          appId = lib.escapeShellArg package.appId;
          origin = lib.escapeShellArg package.origin;
        in
        ''
          app_id=${appId}
          if flatpak --user info "$app_id" >/dev/null 2>&1; then
            echo "Skipping: $app_id is already installed"
          elif timeout --foreground 30m flatpak --user --noninteractive install ${origin} "$app_id"; then
            echo "Installed: $app_id"
          else
            echo "WARNING: failed to install $app_id; continuing with the remaining packages" >&2
            failed_apps="$failed_apps $app_id"
          fi
        '';
      resilientInstaller = pkgs.writeShellApplication {
        name = "flatpak-managed-install-resilient";
        runtimeInputs = with pkgs; [
          coreutils
          flatpak
        ];
        text = ''
          failed_apps=""
          icon_index="$HOME/.local/share/flatpak/exports/share/icons/hicolor/index.theme"
          if [[ -e "$icon_index" && ! -w "$icon_index" ]]; then
            chmod u+w "$icon_index"
          fi

          ${lib.concatMapStringsSep "\n" installPackage config.services.flatpak.packages}

          if [[ -n "$failed_apps" ]]; then
            echo "WARNING: some Flatpaks could not be installed:$failed_apps" >&2
          fi
        '';
      };
    in
    {
      imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        restartOnFailure.enable = false;
      };

      systemd.user.services.flatpak-managed-install.Service.ExecStart = lib.mkForce (
        lib.getExe resilientInstaller
      );
    };
}
