{
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs.sfd-nix.url = "git+https://forge.asnk.io/sugar/sfd-nix";

  flake-file.prune-lock.program = lib.mkForce (
    pkgs:
    pkgs.writeShellApplication {
      name = "nix-auto-follow";
      runtimeInputs = [ inputs.nix-auto-follow.packages.${pkgs.stdenv.hostPlatform.system}.default ];
      text = ''
        auto-follow --ignore sfd-nix "$1" > "$2"
      '';
    }
  );

  nixos =
    {
      user,
      config,
      ...
    }:
    {
      imports = [
        inputs.sfd-nix.nixosModules.default
        ({ lib, ... }: {
          options.security.polkit.enablePkexecWrapper = lib.mkEnableOption ''
            the legacy pkexec wrapper expected by sing-box-for-desktop
          '';
        })
      ];

      users = {
        groups.sing-box = { };
        users.${user.username}.extraGroups = [ "sing-box" ];
      };

      sops.secrets."sing-box-profile" = {
        group = "sing-box";
        mode = "0440";
      };

      nix.settings = {
        substituters = [
          "https://sfd-nix.cachix.org"
        ];
        trusted-public-keys = [
          "sfd-nix.cachix.org-1:SX5EpvFvgFZXgG94/0fX1L+lUWQ90dPq0Ieor7/rDig="
        ];
      };

      programs.sing-box-for-desktop = {
        enable = true;
        settings = {
          startAtLogin = true;
          tray = {
            enable = true;
            keepInBackground = true;
          };
          language = "en";
          appearance = "dark";
          theme = "blue";

          terminal = {
            lightTheme = "Alabaster";
            darkTheme = "Afterglow";
            fontFamily = "Iosevka";
            fontSize = 14;
            alwaysShowSymbolBar = true;

            darkCustomTheme = {
              background = "#101010";
              foreground = "#eeeeee";
              cursor = "#eeeeee";
            };
          };

          core = {
            insecureMode = false;
            disableDeprecatedWarnings = true;
          };
        };

        profiles = [
          {
            name = "Default";
            configurationPath = config.sops.secrets."sing-box-profile".path;
          }
        ];
        defaultProfile = "Default";
      };
    };
}
