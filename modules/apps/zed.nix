_: {
  home =
    { pkgs, ... }:
    {
      programs.zed-editor = {
        enable = true;
        package = pkgs.zed-editor;

        extensions = [
          "zedokai"
        ];

        userSettings = {
          disable_ai = false;
          title_bar.show_sign_in = false;

          theme = {
            mode = "system";
            light = "Zedokai";
            dark = "Zedokai";
          };

          agent = {
            dock = "right";
            favorite_models = [ ];
            model_parameters = [ ];
          };

          outline_panel.dock = "left";
          collaboration_panel.dock = "left";
          git_panel.dock = "left";
          project_panel.dock = "left";

          icon_theme = "Zed (Default)";
          vim_mode = true;
          restore_on_startup = "empty_tab";

          ui_font_size = 16;
          ui_font_family = "Noto Sans CJK SC";
          ui_font_fallbacks = [
            "Noto Sans"
            "Noto Color Emoji"
          ];
          buffer_font_size = 16;
          buffer_font_family = "JetBrains Mono";
          buffer_font_fallbacks = [
            "Noto Sans Mono CJK SC"
            "Noto Sans Mono"
            "NotoSansM Nerd Font Mono"
            "Noto Sans Symbols"
            "Noto Sans Symbols 2"
            "Noto Color Emoji"
          ];

          tab_size = 4;
          formatter = "auto";
          format_on_save = "on";
          load_direnv = "shell_hook";

          inlay_hints = {
            enabled = false;
            show_type_hints = true;
            show_parameter_hints = true;
            show_other_hints = true;
            show_background = true;
            toggle_on_modifiers_press.alt = true;
          };

          scrollbar.show = "always";

          terminal.shell.program = "${pkgs.fish}/bin/fish";

          languages.Zig = {
            format_on_save = "on";
            language_servers = [
              "zls"
              "..."
            ];
            code_actions_on_format = {
              "source.fixAll" = true;
              "source.organizeImports" = true;
            };
          };

          lsp = {
            json-language-server.settings.json.schemas = [
              {
                fileMatch = [ "package.json" ];
                url = "https://www.schemastore.org/package";
              }
            ];
          };
        };

        userKeymaps = [
          {
            context = "Workspace";
            bindings = {
              "ctrl-h" = "pane::ActivatePreviousItem";
              "ctrl-l" = "pane::ActivateNextItem";
            };
          }
          {
            context = "VimControl && !menu";
            bindings = {
              "ctrl-h" = "pane::ActivatePreviousItem";
              "ctrl-l" = "pane::ActivateNextItem";
            };
          }
          {
            bindings = {
              "ctrl-shift-h" = "workspace::ActivatePaneLeft";
              "ctrl-shift-l" = "workspace::ActivatePaneRight";
              "ctrl-shift-k" = "workspace::ActivatePaneUp";
              "ctrl-shift-j" = "workspace::ActivatePaneDown";
              "ctrl-shift-t" = "workspace::NewCenterTerminal";
            };
          }
        ];
      };
    };
}
