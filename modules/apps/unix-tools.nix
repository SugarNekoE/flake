{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  home =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

      home.packages = with pkgs; [
        devenv
        any-nix-shell
        fastfetch
        nix-output-monitor
        cachix
      ];

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
      };

      programs.direnv.enable = true;

      programs.nix-index-database.comma.enable = true;

      programs.command-not-found.enable = false;

      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
      };
    };
}
