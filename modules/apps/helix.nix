_: {
  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.helix ];
      environment.variables = {
        EDITOR = "hx";
        VISUAL = "hx";
        SUDO_EDITOR = "hx";
        SOPS_EDITOR = "hx";
      };
    };

  home =
    { pkgs, ... }:
    {
      stylix.targets.helix.enable = true;

      home.sessionVariables = {
        IHP_EDITOR = "hx";
        SUDO_EDITOR = "hx";
        SOPS_EDITOR = "hx";
      };

      programs.fish.shellAliases = {
        v = "hx";
        vi = "hx";
        vim = "hx";
      };

      programs.helix = {
        enable = true;
        defaultEditor = true;

        extraPackages = with pkgs; [
          nixd
          nixfmt
          marksman
          taplo
          vscode-langservers-extracted
          yaml-language-server
          yamlfmt
          prettier
          wl-clipboard
        ];

        settings.editor = {
          line-number = "relative";
          cursorline = true;
          bufferline = "multiple";
          scrolloff = 10;
          default-yank-register = "+";

          cursor-shape.insert = "bar";
          file-picker.hidden = false;
          indent-guides.render = true;
          whitespace.render = {
            tab = "all";
            space = "none";
            newline = "none";
          };

          end-of-line-diagnostics = "hint";
          inline-diagnostics.cursor-line = "warning";
        };

        languages = {
          language-server = {
            nixd.config.nixd.formatting.command = [ "nixfmt" ];
            vscode-json-language-server.config.json = {
              validate.enable = true;
              schemas = [
                {
                  fileMatch = [ "package.json" ];
                  url = "https://www.schemastore.org/package";
                }
              ];
            };
            yaml-language-server.config = {
              redhat.telemetry.enabled = false;
              yaml = {
                keyOrdering = false;
                validate = true;
                schemaStore.enable = true;
              };
            };
          };

          language = [
            {
              name = "nix";
              roots = [ "flake.nix" ];
              language-servers = [ "nixd" ];
              auto-format = true;
              formatter.command = "nixfmt";
            }
            {
              name = "markdown";
              language-servers = [ "marksman" ];
              auto-format = true;
              formatter = {
                command = "prettier";
                args = [
                  "--stdin-filepath"
                  "%{buffer_name}"
                ];
              };
            }
            {
              name = "toml";
              language-servers = [ "taplo" ];
              auto-format = true;
              indent = {
                tab-width = 2;
                unit = "  ";
              };
            }
            {
              name = "json";
              language-servers = [ "vscode-json-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettier";
                args = [
                  "--parser"
                  "json"
                  "--stdin-filepath"
                  "%{buffer_name}"
                ];
              };
            }
            {
              name = "jsonc";
              language-servers = [ "vscode-json-language-server" ];
              auto-format = true;
              formatter = {
                command = "prettier";
                args = [
                  "--parser"
                  "jsonc"
                  "--stdin-filepath"
                  "%{buffer_name}"
                ];
              };
            }
            {
              name = "yaml";
              language-servers = [ "yaml-language-server" ];
              auto-format = true;
              formatter = {
                command = "yamlfmt";
                args = [ "-in" ];
              };
            }
          ];
        };
      };
    };
}
