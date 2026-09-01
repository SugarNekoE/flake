{
  home =
    { pkgs, ... }:
    let
      lazygitWithCommitMessagePanel = pkgs.lazygit.overrideAttrs (oldAttrs: {
        patches = (oldAttrs.patches or [ ]) ++ [
          (pkgs.fetchurl {
            url = "https://github.com/jesseduffield/lazygit/commit/e6e4f7232c8e31039d45aab191cb617e870590b8.patch";
            hash = "sha256-/KSnJFL8fPlJPoX1Nrh5brdqTDMGDORa79Xa+1aLgUU=";
          })
        ];
      });
    in
    {
      programs.lazygit = {
        enable = true;
        package = lazygitWithCommitMessagePanel;
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
                  type = "menu";
                  title = "Breaking change?";
                  key = "Breaking";
                  options = [
                    {
                      name = "No";
                      value = "";
                      key = "n";
                    }
                    {
                      name = "Yes";
                      value = "!";
                      key = "y";
                    }
                  ];
                }
              ];
              output = "commitMessagePanel";
              command = "printf '%s(%s)%s: ' {{.Form.Type | quote}} {{.Form.Scope | quote}} {{.Form.Breaking | quote}}";
            }
          ];
        };
      };

      stylix.targets.lazygit.enable = true;
    };
}
