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
        sd
        nil
        mtr
        duf
        nixd
        tldr
        dust
        gping
        doggo
        procs
        devenv
        cachix
        ripgrep
        fastfetch
        nix-output-monitor
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
      };

      programs.htop.enable = true;

      programs.lazygit.enable = true;

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
        fzf.enable = true;
        bat.enable = true;
        btop.enable = true;
        yazi.enable = true;
        zellij.enable = true;
        lazygit.enable = true;
      };
    };
}
