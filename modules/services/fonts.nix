{ lib, ... }:
let
  serifFonts = [
    "Noto Serif CJK SC"
    "Noto Serif"
    "Noto Color Emoji"
  ];
  sansSerifFonts = [
    "Noto Sans CJK SC"
    "Noto Sans"
    "Noto Color Emoji"
  ];
  monospaceFonts = [
    "JetBrainsMono Nerd Font Mono"
    "JetBrains Mono"
    "Noto Sans CJK SC"
    "Noto Color Emoji"
  ];
  fallbackFonts = {
    serif = lib.mkForce serifFonts;
    sansSerif = lib.mkForce sansSerifFonts;
    monospace = lib.mkForce monospaceFonts;
    emoji = lib.mkForce [ "Noto Color Emoji" ];
  };
in
{
  flake.modules.nixos.fonts =
    { pkgs, ... }:
    {
      fonts = {
        fontDir.enable = true;
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          jetbrains-mono
          nerd-fonts.jetbrains-mono
        ];

        enableGhostscriptFonts = false;
        enableDefaultPackages = false;

        fontconfig.defaultFonts = fallbackFonts;
      };
    };

  flake.modules.homeManager.fonts.fonts.fontconfig = {
    enable = true;
    defaultFonts = fallbackFonts;
  };
}
