{ inputs, ... }:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim/nixos-26.05";

  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.neovim ];
      environment.variables = {
        EDITOR = "nvim";
        VISUAL = "nvim";
        IHP_EDITOR = "nvim";
        SUDO_EDITOR = "nvim";
        SOPS_EDITOR = "nvim";
      };
    };

  home =
    { config, pkgs, ... }:
    let
      raw = code: { __raw = code; };
      map = mode: key: action: desc: {
        inherit mode key action;
        options.desc = desc;
      };
      exprMap =
        key: action: desc:
        let
          keymap = map "i" key action desc;
        in
        keymap
        // {
          options = keymap.options // {
            expr = true;
          };
        };
      projectPicker = action: desc: {
        inherit action;
        options.desc = desc;
        settings.cwd = raw ''vim.fs.root(0, { ".git", "flake.nix" }) or vim.fn.getcwd()'';
      };
    in
    {
      imports = [ inputs.nixvim.homeModules.nixvim ];
      stylix.targets.nixvim.enable = true;

      programs.nixvim = {
        enable = true;
        nixpkgs.useGlobalPackages = true;
        viAlias = true;
        vimAlias = true;
        withPython3 = false;
        withRuby = false;
        withNodeJs = false;

        extraPackages = with pkgs; [
          fd
          git
          ripgrep
          nixfmt
          yamlfmt
          prettier
          wl-clipboard
        ];

        globals = {
          mapleader = " ";
          maplocalleader = "\\";
        };
        opts = {
          number = true;
          relativenumber = true;
          cursorline = true;
          scrolloff = 10;
          signcolumn = "yes";
          clipboard = "unnamedplus";
          ignorecase = true;
          smartcase = true;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
          splitbelow = true;
          splitright = true;
          termguicolors = true;
          undofile = true;
          updatetime = 250;
          completeopt = [
            "menu"
            "menuone"
            "noselect"
          ];
        };
        diagnostic.settings = {
          severity_sort = true;
          virtual_text = true;
        };

        plugins = {
          friendly-snippets.enable = true;
          mini = {
            enable = true;
            modules = {
              ai = { };
              align = { };
              completion = { };
              git = { };
              icons = { };
              move = { };
              pairs = { };
              splitjoin = { };
              statusline = { };
              trailspace = { };
              jump2d.mappings.start_jumping = "<leader>j";
              indentscope.draw.animation = raw ''require("mini.indentscope").gen_animation.none()'';
              hipatterns.highlighters = {
                fixme = {
                  pattern = "%f[%w]()FIXME()%f[%W]";
                  group = "MiniHipatternsFixme";
                };
                hack = {
                  pattern = "%f[%w]()HACK()%f[%W]";
                  group = "MiniHipatternsHack";
                };
                todo = {
                  pattern = "%f[%w]()TODO()%f[%W]";
                  group = "MiniHipatternsTodo";
                };
                note = {
                  pattern = "%f[%w]()NOTE()%f[%W]";
                  group = "MiniHipatternsNote";
                };
                hex_color = raw ''require("mini.hipatterns").gen_highlighter.hex_color()'';
              };
              snippets = {
                snippets = [ (raw ''require("mini.snippets").gen_loader.from_lang()'') ];
                mappings = {
                  jump_next = "";
                  jump_prev = "";
                };
              };
              diff.view = {
                style = "sign";
                signs = {
                  add = "+";
                  change = "~";
                  delete = "_";
                };
              };
              clue = {
                triggers = [
                  {
                    mode = "n";
                    keys = "<leader>";
                  }
                  {
                    mode = "x";
                    keys = "<leader>";
                  }
                  {
                    mode = "n";
                    keys = "g";
                  }
                  {
                    mode = "x";
                    keys = "g";
                  }
                  {
                    mode = "n";
                    keys = "z";
                  }
                  {
                    mode = "x";
                    keys = "z";
                  }
                  {
                    mode = "n";
                    keys = "<C-w>";
                  }
                ];
                clues = [
                  {
                    mode = "n";
                    keys = "<leader>c";
                    desc = "Code";
                  }
                  {
                    mode = "x";
                    keys = "<leader>c";
                    desc = "Code";
                  }
                  {
                    mode = "n";
                    keys = "<leader>g";
                    desc = "Git";
                  }
                  {
                    mode = "n";
                    keys = "<leader>s";
                    desc = "Search";
                  }
                  (raw ''require("mini.clue").gen_clues.g()'')
                  (raw ''require("mini.clue").gen_clues.z()'')
                  (raw ''require("mini.clue").gen_clues.windows()'')
                ];
                window.delay = 300;
              };
            };
          };

          treesitter = {
            enable = true;
            highlight.enable = true;
            grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
              bash
              json
              json5
              lua
              markdown
              markdown_inline
              nix
              toml
              vim
              vimdoc
              yaml
            ];
          };

          lspconfig.enable = true;
          conform-nvim = {
            enable = true;
            settings = {
              formatters_by_ft = {
                nix = [ "nixfmt" ];
                markdown = [ "prettier" ];
                toml = [ "taplo" ];
                json = [ "prettier" ];
                jsonc = [ "prettier" ];
                yaml = [ "yamlfmt" ];
              };
              format_on_save = {
                timeout_ms = 1500;
                lsp_format = "fallback";
              };
            };
          };
          fzf-lua = {
            enable = true;
            settings.files.hidden = true;
            keymaps = {
              "<leader>f" = projectPicker "files" "Find files";
              "<leader>r" = projectPicker "live_grep" "Search project";
              "<leader>b" = {
                action = "buffers";
                options.desc = "Find buffers";
              };
              "<leader>d" = {
                action = "diagnostics_workspace";
                options.desc = "Find diagnostics";
              };
              "<leader>sk" = {
                action = "keymaps";
                options.desc = "Find keymaps";
              };
            };
          };
        };

        lsp = {
          servers = {
            "*".config.capabilities = raw ''require("mini.completion").get_lsp_capabilities()'';
            nixd = {
              enable = true;
              config.settings.nixd.formatting.command = [ "nixfmt" ];
            };
            marksman.enable = true;
            taplo.enable = true;
            jsonls = {
              enable = true;
              config.settings.json = {
                validate.enable = true;
                schemas = [
                  {
                    fileMatch = [ "package.json" ];
                    url = "https://www.schemastore.org/package";
                  }
                ];
              };
            };
            yamlls = {
              enable = true;
              config.settings = {
                redhat.telemetry.enabled = false;
                yaml = {
                  keyOrdering = false;
                  validate = true;
                  schemaStore.enable = true;
                };
              };
            };
          };
          keymaps = [
            (map "n" "gd" (raw "vim.lsp.buf.definition") "Go to definition")
            (map "n" "gr" (raw "vim.lsp.buf.references") "Find references")
            (map "n" "K" (raw "vim.lsp.buf.hover") "Hover documentation")
            (map "n" "<leader>cr" (raw "vim.lsp.buf.rename") "Rename symbol")
            (map "n" "<leader>ca" (raw "vim.lsp.buf.code_action") "Code action")
          ];
          onAttach = ''
            vim.schedule(function() require("mini.clue").ensure_buf_triggers(bufnr) end)
          '';
        };

        keymaps = [
          (map "n" "<Esc>" "<Cmd>nohlsearch<CR>" "Clear search highlights")
          (exprMap "<Tab>" (raw ''
            function()
              if vim.fn.pumvisible() == 1 then return "<C-n>" end
              local session = require("mini.snippets").session.get()
              if session and session.buf_id == vim.api.nvim_get_current_buf() then
                return "<Cmd>lua MiniSnippets.session.jump('next')<CR>"
              end
              if vim.snippet.active({ direction = 1 }) then
                return "<Cmd>lua vim.snippet.jump(1)<CR>"
              end
              return "<Tab>"
            end
          '') "Next completion or snippet tabstop")
          (exprMap "<S-Tab>" (raw ''
            function()
              if vim.fn.pumvisible() == 1 then return "<C-p>" end
              local session = require("mini.snippets").session.get()
              if session and session.buf_id == vim.api.nvim_get_current_buf() then
                return "<Cmd>lua MiniSnippets.session.jump('prev')<CR>"
              end
              if vim.snippet.active({ direction = -1 }) then
                return "<Cmd>lua vim.snippet.jump(-1)<CR>"
              end
              return "<S-Tab>"
            end
          '') "Previous completion or snippet tabstop")
          (exprMap "<CR>" (raw ''
            function()
              if vim.fn.pumvisible() == 1 and vim.fn.complete_info().selected ~= -1 then
                return "<C-y>"
              end
              return require("mini.pairs").cr()
            end
          '') "Accept completion or insert newline")
          (map "n" "<leader>gd" "<Cmd>lua MiniDiff.toggle_overlay(0)<CR>" "Toggle Git diff overlay")
          (map "n" "<leader>gs" "<Cmd>Git status<CR>" "Git status")
          (map "n" "<leader>gl" "<Cmd>Git log --oneline --decorate<CR>" "Git log")
          (map "n" "<leader>cd" (raw "vim.diagnostic.open_float") "Line diagnostics")
          (map "n" "<leader>cw" "<Cmd>lua MiniTrailspace.trim()<CR>" "Trim trailing whitespace")
          (map [ "n" "x" ] "<leader>cf"
            ''<Cmd>lua require("conform").format({ async = true, lsp_format = "fallback" })<CR>''
            "Format"
          )
        ];

        extraConfigLuaPost = ''require("mini.clue").ensure_all_triggers()'';
      };
    };
}
