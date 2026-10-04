{ inputs, ... }:
let
  withWallpaper =
    {
      url,
      hash,
    }:
    let
      wallpaperModule =
        { pkgs, ... }:
        {
          stylix.image = pkgs.fetchurl { inherit url hash; };
        };
    in
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.stylix ];
      nixosModule = wallpaperModule;
      darwinModule = wallpaperModule;
    };

  themeModule =
    { pkgs, ... }:
    {
      stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        base16Scheme = {
          system = "base16";
          name = "Monokai Pro";
          author = "Monokai";
          variant = "dark";
          palette = {
            base00 = "#2D2A2E";
            base01 = "#403E41";
            base02 = "#5B595C";
            base03 = "#727072";
            base04 = "#939293";
            base05 = "#FCFCFA";
            base06 = "#FCFCFA";
            base07 = "#FCFCFA";
            base08 = "#FF6188";
            base09 = "#FC9867";
            base0A = "#FFD866";
            base0B = "#A9DC76";
            base0C = "#78DCE8";
            base0D = "#78DCE8";
            base0E = "#AB9DF2";
            base0F = "#FC9867";
          };
        };
        fonts = {
          serif = {
            name = "Noto Serif CJK SC";
            package = pkgs.noto-fonts-cjk-serif;
          };
          sansSerif = {
            name = "Noto Sans CJK SC";
            package = pkgs.noto-fonts-cjk-sans;
          };
          monospace = {
            name = "NotoMono Nerd Font";
            package = pkgs.nerd-fonts.noto;
          };
          emoji = {
            name = "Noto Color Emoji";
            package = pkgs.noto-fonts-color-emoji;
          };
          sizes = {
            terminal = 14;
          };
        };
        opacity.terminal = 1.0;
      };
    };
in
{
  flake-file.inputs.stylix.url = "github:nix-community/stylix/release-26.05";

  aspectHelpers.stylix = { inherit withWallpaper; };

  nixos =
    { pkgs, ... }:
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        themeModule
      ];

      stylix = {
        targets.console.enable = true;
        cursor = {
          name = "macOS";
          package = pkgs.apple-cursor;
          size = 24;
        };
        icons = {
          enable = true;
          package = pkgs.la-capitaine-icon-theme;
          dark = "la-capitaine-icon-theme";
          light = "la-capitaine-icon-theme";
        };
      };
    };

  darwin = {
    imports = [
      inputs.stylix.darwinModules.stylix
      themeModule
    ];
  };

  home.stylix.autoEnable = false;
}
