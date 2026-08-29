{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  nixos.stylix.targets.grub.enable = true;

  home =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      home.packages = with pkgs; [
        gh
        fd
        nil
        nixd
        devenv
        fastfetch
        nix-output-monitor
        cachix
        ripgrep
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
      };

      programs.htop.enable = true;

      programs.btop.enable = true;

      programs.nix-index-database.comma.enable = true;

      programs.command-not-found.enable = false;

      programs.zellij.enable = true;

      programs.bat.enable = true;

      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--cmd cd" ];
      };

      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.eza = {
        enable = true;
        enableFishIntegration = true;
        git = true;
      };

      programs.yazi = {
        enable = true;
        enableFishIntegration = true;
      };

      stylix.targets = {
        btop.enable = true;
        zellij.enable = true;
        yazi.enable = true;
        fzf.enable = true;
        bat.enable = true;
      };
    };
}
