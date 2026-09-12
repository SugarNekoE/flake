_: {
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
    { pkgs, ... }:
    {
      stylix.targets.neovim.enable = true;

      programs.neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;
        withPython3 = false;
        withRuby = false;
        withNodeJs = false;

        extraPackages = with pkgs; [
          fd
          fzf
          ripgrep
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

        plugins = with pkgs.vimPlugins; [
          mini-nvim
          fzf-lua
          nvim-lspconfig
          conform-nvim
          (nvim-treesitter.withPlugins (
            parsers: with parsers; [
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
            ]
          ))
        ];

        initLua = ''
          vim.g.mapleader = " "
          vim.g.maplocalleader = "\\"
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.cursorline = true
          vim.opt.scrolloff = 10
          vim.opt.signcolumn = "yes"
          vim.opt.clipboard = "unnamedplus"
          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.expandtab = true
          vim.opt.shiftwidth = 2
          vim.opt.tabstop = 2
          vim.opt.splitbelow = true
          vim.opt.splitright = true
          vim.opt.termguicolors = true
          vim.opt.undofile = true
          vim.opt.updatetime = 250
          vim.opt.completeopt = { "menu", "menuone", "noselect" }

          require("mini.ai").setup()
          require("mini.icons").setup()
          require("mini.completion").setup()
          require("mini.pairs").setup()
          require("mini.statusline").setup()

          -- Parsers and queries come from Nix; other filetypes use Vim syntax.
          vim.api.nvim_create_autocmd("FileType", {
            callback = function(args)
              local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
              if lang and vim.treesitter.language.add(lang) then
                vim.treesitter.start(args.buf, lang)
              end
            end,
          })

          vim.diagnostic.config({ severity_sort = true, virtual_text = true })
          vim.lsp.config("*", {
            capabilities = require("mini.completion").get_lsp_capabilities(),
          })
          vim.lsp.config("nixd", {
            settings = { nixd = { formatting = { command = { "nixfmt" } } } },
          })
          vim.lsp.config("jsonls", {
            settings = {
              json = {
                validate = { enable = true },
                schemas = {
                  { fileMatch = { "package.json" }, url = "https://www.schemastore.org/package" },
                },
              },
            },
          })
          vim.lsp.config("yamlls", {
            settings = {
              redhat = { telemetry = { enabled = false } },
              yaml = { keyOrdering = false, validate = true, schemaStore = { enable = true } },
            },
          })
          vim.lsp.enable({ "nixd", "marksman", "taplo", "jsonls", "yamlls" })

          vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
              local function map(key, action, desc)
                vim.keymap.set("n", key, action, { buffer = args.buf, desc = desc })
              end
              map("gd", vim.lsp.buf.definition, "Go to definition")
              map("gr", vim.lsp.buf.references, "Find references")
              map("K", vim.lsp.buf.hover, "Hover documentation")
              map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
              map("<leader>ca", vim.lsp.buf.code_action, "Code action")
            end,
          })

          require("conform").setup({
            formatters_by_ft = {
              nix = { "nixfmt" },
              markdown = { "prettier" },
              toml = { "taplo" },
              json = { "prettier" },
              jsonc = { "prettier" },
              yaml = { "yamlfmt" },
            },
            format_on_save = { timeout_ms = 1500, lsp_format = "fallback" },
          })

          local fzf = require("fzf-lua")
          fzf.setup({ files = { hidden = true } })
          local function project_picker(picker)
            return function()
              local root = vim.fs.root(0, { ".git", "flake.nix" }) or vim.fn.getcwd()
              fzf[picker]({ cwd = root })
            end
          end
          vim.keymap.set("n", "<leader>f", project_picker("files"), { desc = "Find files" })
          vim.keymap.set("n", "<leader>r", project_picker("live_grep"), { desc = "Search project" })
          vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Find buffers" })
          vim.keymap.set("n", "<leader>d", fzf.diagnostics_workspace, { desc = "Find diagnostics" })
          vim.keymap.set("n", "<leader>sk", fzf.keymaps, { desc = "Find keymaps" })
          vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
          vim.keymap.set({ "n", "x" }, "<leader>cf", function()
            require("conform").format({ async = true, lsp_format = "fallback" })
          end, { desc = "Format" })
        '';
      };
    };
}
