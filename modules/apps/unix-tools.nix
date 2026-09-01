{ inputs, ... }:
{
  flake-file.inputs.nix-index-database.url = "github:nix-community/nix-index-database";

  nixos.stylix.targets.grub.enable = true;

  home =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-index-database.homeModules.nix-index ];

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

      programs.lazygit = {
        enable = true;
        enableFishIntegration = true;
        settings = {
          git.commit.signOff = true;
          services."forge.asnk.io" = "gitea:forge.asnk.io";
          customCommands = [
            {
              key = "C";
              context = "files";
              description = "Create a Conventional Commit";
              loadingText = "Creating commit";
              prompts = [
                {
                  type = "menu";
                  title = "Commit type";
                  key = "Type";
                  options = [
                    {
                      name = "build";
                      description = "Build system or dependencies";
                      value = "build";
                      key = "b";
                    }
                    {
                      name = "chore";
                      description = "Maintenance work";
                      value = "chore";
                      key = "c";
                    }
                    {
                      name = "ci";
                      description = "CI configuration";
                      value = "ci";
                      key = "i";
                    }
                    {
                      name = "docs";
                      description = "Documentation";
                      value = "docs";
                      key = "d";
                    }
                    {
                      name = "feat";
                      description = "New feature";
                      value = "feat";
                      key = "f";
                    }
                    {
                      name = "fix";
                      description = "Bug fix";
                      value = "fix";
                      key = "x";
                    }
                    {
                      name = "perf";
                      description = "Performance improvement";
                      value = "perf";
                      key = "p";
                    }
                    {
                      name = "refactor";
                      description = "Code restructuring";
                      value = "refactor";
                      key = "r";
                    }
                    {
                      name = "revert";
                      description = "Revert a previous change";
                      value = "revert";
                      key = "v";
                    }
                    {
                      name = "style";
                      description = "Formatting only";
                      value = "style";
                      key = "s";
                    }
                    {
                      name = "test";
                      description = "Tests";
                      value = "test";
                      key = "t";
                    }
                  ];
                }
                {
                  type = "input";
                  title = "Scope";
                  key = "Scope";
                }
                {
                  type = "input";
                  title = "Commit message";
                  key = "Message";
                }
              ];
              command = ''git commit --signoff --message "$(printf '%s(%s): %s' {{.Form.Type | quote}} {{.Form.Scope | quote}} {{.Form.Message | quote}})"'';
            }
          ];
        };
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
