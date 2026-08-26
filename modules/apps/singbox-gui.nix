{
  inputs,
  ...
}:
let
  withProfile =
    {
      name ? "Default",
      sopsFile,
    }:
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.singbox-gui ];
      nixosModule =
        { config, lib, ... }:
        let
          hasProfile = builtins.pathExists sopsFile;
        in
        lib.mkIf hasProfile {
          sops.secrets."sing-box-profile" = {
            format = "json";
            inherit sopsFile;
            key = "";
            group = "sing-box";
            mode = "0440";
          };

          programs.sing-box-for-desktop = {
            profiles = [
              {
                inherit name;
                configurationPath = config.sops.secrets."sing-box-profile".path;
              }
            ];
            defaultProfile = name;
          };
        };
    };
in
{
  flake-file.inputs.sfd-nix.url = "git+https://forge.asnk.io/sugar/sfd-nix";

  aspectHelpers.singbox-gui = { inherit withProfile; };

  nixos =
    { config, user, ... }:
    let
      colors = config.lib.stylix.colors.withHashtag;
      catppuccinTerminal = {
        background = colors.base00;
        foreground = colors.base05;
        cursor = colors.base06;
        cursorAccent = colors.base00;
        selectionBackground = colors.base02;
        selectionForeground = colors.base06;

        black = colors.base00;
        red = colors.base08;
        green = colors.base0B;
        yellow = colors.base0A;
        blue = colors.base0D;
        magenta = colors.base0E;
        cyan = colors.base0C;
        white = colors.base05;

        brightBlack = colors.base03;
        brightRed = colors.base0F;
        brightGreen = colors.base0B;
        brightYellow = colors.base0A;
        brightBlue = colors.base07;
        brightMagenta = colors.base0E;
        brightCyan = colors.base0C;
        brightWhite = colors.base06;
      };
    in
    {
      imports = [
        inputs.sfd-nix.nixosModules.default
        (
          { lib, ... }:
          {
            options.security.polkit.enablePkexecWrapper = lib.mkEnableOption ''
              the legacy pkexec wrapper expected by sing-box-for-desktop
            '';
          }
        )
      ];

      users = {
        groups.sing-box = { };
        users.${user.username}.extraGroups = [ "sing-box" ];
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
          theme = colors.base0D;

          terminal = {
            lightTheme = "Alabaster";
            darkTheme = "";
            fontFamily = "JetBrains Mono";
            fontSize = 14;
            alwaysShowSymbolBar = true;
            darkCustomTheme = catppuccinTerminal;
          };

          core = {
            insecureMode = false;
            disableDeprecatedWarnings = true;
          };
        };

      };
    };
}
