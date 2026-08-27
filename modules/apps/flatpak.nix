{ inputs, lib, ... }:
let
  withPackages =
    packages:
    {
      _class = "aspects";
    }
    // lib.optionalAttrs (packages != [ ]) {
      imports = [ inputs.self.modules.aspects.flatpak ];
      nixosModule.services.flatpak.packages = packages;
    };
in
{
  flake-file.inputs.nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

  aspectHelpers.flatpak = { inherit withPackages; };

  nixos =
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
          if flatpak --system info "$app_id" >/dev/null 2>&1; then
            echo "Skipping: $app_id is already installed"
          elif timeout --foreground 30m flatpak --system --noninteractive install ${origin} "$app_id"; then
            echo "Installed: $app_id"
          else
            echo "WARNING: failed to install $app_id; continuing with the remaining packages" >&2
            failed_apps="$failed_apps $app_id"
          fi
        '';
      managedAppPattern = lib.concatStringsSep "|" (
        map (package: lib.escapeShellArg package.appId) config.services.flatpak.packages
      );
      resilientInstaller = pkgs.writeShellApplication {
        name = "flatpak-managed-install-resilient";
        runtimeInputs = with pkgs; [
          coreutils
          flatpak
        ];
        text = ''
          failed_apps=""
          icon_index="/var/lib/flatpak/exports/share/icons/hicolor/index.theme"
          if [[ -e "$icon_index" && ! -w "$icon_index" ]]; then
            chmod u+w "$icon_index"
          fi

          while IFS= read -r app_id; do
            case "$app_id" in
              ${managedAppPattern}) ;;
              *)
                if flatpak --system --noninteractive uninstall "$app_id"; then
                  echo "Removed unmanaged Flatpak: $app_id"
                else
                  echo "WARNING: failed to remove unmanaged Flatpak: $app_id" >&2
                fi
                ;;
            esac
          done < <(flatpak --system list --app --columns=application)

          ${lib.concatMapStringsSep "\n" installPackage config.services.flatpak.packages}

          if ! flatpak --system --noninteractive uninstall --unused; then
            echo "WARNING: failed to remove some unused Flatpak runtimes" >&2
          fi

          if [[ -n "$failed_apps" ]]; then
            echo "WARNING: some Flatpaks could not be installed:$failed_apps" >&2
          fi
        '';
      };
    in
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        uninstallUnmanaged = true;
        uninstallUnused = true;
        restartOnFailure.enable = false;
      };

      systemd.services.flatpak-managed-install.serviceConfig.ExecStart = lib.mkForce (
        lib.getExe resilientInstaller
      );

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
}
