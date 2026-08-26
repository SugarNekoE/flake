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

  flake.modules.nixos.stylix =
    { pkgs, ... }:
    {
      imports = [ inputs.stylix.nixosModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = false;
        polarity = "dark";
        base16Scheme = "${inputs.stylix.inputs.tinted-schemes}/base16/catppuccin-macchiato.yaml";
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

  flake.modules.homeManager.stylix.stylix.autoEnable = false;
}
