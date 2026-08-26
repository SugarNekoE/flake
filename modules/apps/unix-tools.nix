{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  home =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      home.packages = with pkgs; [
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

      programs.direnv.enable = true;

      programs.htop.enable = true;

      programs.btop.enable = true;

      programs.nix-index-database.comma.enable = true;

      programs.command-not-found.enable = false;

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

      programs.zellij = {
        enable = true;
        exitShellOnExit = true;
      };

      stylix.targets = {
        btop.enable = true;
        zellij.enable = true;
      };
    };
}
