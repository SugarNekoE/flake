{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  nixos.stylix.targets.grub.enable = true;

  home =
    { pkgs, ... }:
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
        inputs.self.modules.homeManager.lazygit
      ];

      home.packages = with pkgs; [
        fd
        sd
        jq
        nil
        mtr
        duf
        dig
        nixd
        tldr
        dust
        gping
        doggo
        procs
        socat
        devenv
        cachix
        killall
        openssl
        ripgrep
        fastfetch
        wl-clipboard
        nix-output-monitor
      ];

      programs.nh.enable = true;

      programs.bat.enable = true;

      programs.htop.enable = true;

      programs.btop.enable = true;

      programs.command-not-found.enable = false;

      programs.nix-index-database.comma.enable = true;

      programs.gh = {
        enable = true;
        gitCredentialHelper.enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
      };

      programs.fzf = {
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

      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        enableFishIntegration = true;
        options = [ "--cmd cd" ];
      };

      programs.zellij = {
        enable = true;
        settings = {
          session_serialization = false;
          show_startup_tips = false;
        };
      };

      programs.nix-index = {
        enable = true;
        enableFishIntegration = true;
      };

      stylix.targets = {
        fzf.enable = true;
        bat.enable = true;
        btop.enable = true;
        yazi.enable = true;
        zellij.enable = true;
      };
    };
}
