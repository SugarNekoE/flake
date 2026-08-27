{ inputs, ... }:
let
  withWallpaper =
    {
      url,
      hash,
    }:
    {
      _class = "aspects";
      imports = [ inputs.self.modules.aspects.stylix ];
      nixosModule =
        { pkgs, ... }:
        {
          stylix.image = pkgs.fetchurl { inherit url hash; };
        };
    };
in
{
  flake-file.inputs.stylix = {
    url = "github:nix-community/stylix/release-26.05";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  aspectHelpers.stylix = { inherit withWallpaper; };

  nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

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
        # These fonts apply to the explicitly enabled Stylix targets only;
        # modules/services/fonts.nix defines the system-wide fallback order.
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
            name = "NotoSansM Nerd Font Mono";
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
        opacity.terminal = 0.80;
      };
    };

  home.stylix.autoEnable = false;
}
