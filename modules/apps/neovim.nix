{ inputs, ... }:
{
  flake-file.inputs.nixvim.url = "github:nix-community/nixvim/nixos-26.05";

  nixos = {
    imports = [ inputs.nixvim.nixosModules.nixvim ];

    programs.nixvim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
      nixpkgs.source = inputs.nixpkgs;
      colorschemes."monokai-pro" = {
        enable = true;
        settings.filter = "pro";
      };
    };
  };

  home = {
    imports = [ inputs.nixvim.homeModules.nixvim ];

    home.sessionVariables = {
      EDITOR = "nvim";
      IHP_EDITOR = "nvim";
      SUDO_EDITOR = "nvim";
    };

    programs.fish = {
      shellAliases = {
        "v" = "nvim";
        "vi" = "nvim";
        "vim" = "nvim";
      };
    };

    programs.nixvim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
      nixpkgs.source = inputs.nixpkgs;
      colorschemes."monokai-pro" = {
        enable = true;
        settings.filter = "pro";
      };

      imports = [
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          let
            luaAction = action: lib.nixvim.mkRaw "function() ${action} end";
            projectAction =
              action:
              luaAction ''
                local root = vim.fs.root(0, { ".git", "flake.nix", "CMakeLists.txt" }) or vim.uv.cwd()
                ${action}
              '';
          in
          {
            globals = {
              mapleader = " ";
              maplocalleader = "\\";
              markdown_recommended_style = 0;
            };

            opts = {
              autowrite = true;
              backspace = [
                "start"
                "eol"
                "indent"
              ];
              clipboard = "unnamedplus";
              completeopt = [
                "menu"
                "menuone"
                "noselect"
              ];
              conceallevel = 2;
              confirm = true;
              cursorline = true;
              expandtab = true;
              fillchars = {
                foldopen = "";
                foldclose = "";
                fold = " ";
                foldsep = " ";
                diff = "╱";
                eob = " ";
              };
              foldlevel = 99;
              foldmethod = "indent";
              foldtext = "";
              grepformat = "%f:%l:%c:%m";
              grepprg = "rg --vimgrep";
              ignorecase = true;
              inccommand = "nosplit";
              jumpoptions = "view";
              laststatus = 3;
              linebreak = true;
              list = true;
              mouse = "a";
              number = true;
              pumblend = 10;
              pumheight = 10;
              relativenumber = true;
              ruler = false;
              scrolloff = 10;
              sessionoptions = [
                "buffers"
                "curdir"
                "tabpages"
                "winsize"
                "help"
                "globals"
                "skiprtp"
                "folds"
              ];
              shiftround = true;
              shiftwidth = 2;
              showmode = false;
              sidescrolloff = 8;
              signcolumn = "yes";
              smartcase = true;
              smartindent = true;
              smoothscroll = true;
              spelllang = [ "en" ];
              splitbelow = true;
              splitkeep = "screen";
              splitright = true;
              tabstop = 2;
              termguicolors = true;
              timeoutlen = 300;
              undofile = true;
              undolevels = 10000;
              updatetime = 200;
              virtualedit = "block";
              wildignore = [ "*/node_modules/*" ];
              wildmode = "longest:full,full";
              winminwidth = 5;
              wrap = false;
            };

            filetype.extension.mdx = "markdown.mdx";

            diagnostic.settings = {
              underline = true;
              update_in_insert = false;
              virtual_text = true;
              severity_sort = true;
              signs.text = lib.nixvim.mkRaw ''
                {
                  [vim.diagnostic.severity.ERROR] = "",
                  [vim.diagnostic.severity.WARN] = "",
                  [vim.diagnostic.severity.INFO] = "",
                  [vim.diagnostic.severity.HINT] = "",
                }
              '';
            };

            extraPackages = with pkgs; [
              fd
              git
              ripgrep
            ];

            plugins = {
              mini = {
                enable = true;
                mockDevIcons = true;
                modules = {
                  ai = { };
                  basics = {
                    mappings.windows = true;
                    options.extra_ui = true;
                  };
                  bracketed = { };
                  bufremove = { };
                  cmdline = { };
                  comment.options.custom_commentstring = lib.nixvim.mkRaw ''
                    function()
                      return require("ts_context_commentstring.internal").calculate_commentstring()
                        or vim.bo.commentstring
                    end
                  '';
                  diff.view = {
                    style = "sign";
                    signs = {
                      add = "▎";
                      change = "▎";
                      delete = "";
                    };
                  };
                  extra = { };
                  files = {
                    windows = {
                      preview = true;
                      width_focus = 30;
                      width_preview = 30;
                    };
                    options.use_as_default_explorer = false;
                  };
                  icons = { };
                  indentscope.draw.delay = 0;
                  jump = { };
                  move = { };
                  notify = { };
                  pairs = { };
                  pick = { };
                  snippets.snippets = [
                    (lib.nixvim.mkRaw ''require("mini.snippets").gen_loader.from_lang()'')
                  ];
                  starter = { };
                  statusline = { };
                  surround.mappings = {
                    add = "gsa";
                    delete = "gsd";
                    find = "gsf";
                    find_left = "gsF";
                    highlight = "gsh";
                    replace = "gsr";
                    update_n_lines = "gsn";
                  };
                  tabline = { };
                  trailspace = { };
                };
              };

              ts-context-commentstring = {
                enable = true;
                settings.enable_autocmd = false;
              };

              friendly-snippets.enable = true;

              blink-cmp = {
                enable = true;
                settings = {
                  keymap.preset = "enter";
                  completion = {
                    documentation.auto_show = true;
                    menu.draw.treesitter = [ "lsp" ];
                  };
                  signature.enabled = true;
                  snippets.preset = "mini_snippets";
                  sources.default = [
                    "lsp"
                    "path"
                    "snippets"
                    "buffer"
                  ];
                };
              };

              flash = {
                enable = true;
                settings.modes.char.jump_labels = true;
              };

              fzf-lua = {
                enable = true;
                profile = "default";
                settings = {
                  fzf_colors = true;
                  fzf_opts."--no-scrollbar" = true;
                  defaults.formatter = "path.dirname_first";
                  winopts = {
                    width = 0.8;
                    height = 0.8;
                    row = 0.5;
                    col = 0.5;
                    preview.scrollchars = [
                      "┃"
                      ""
                    ];
                  };
                  files = {
                    cwd_prompt = false;
                    hidden = true;
                  };
                };
              };

              neo-tree = {
                enable = true;
                settings = {
                  sources = [
                    "filesystem"
                    "buffers"
                    "git_status"
                  ];
                  open_files_do_not_replace_types = [
                    "terminal"
                    "Trouble"
                    "trouble"
                    "qf"
                    "Outline"
                  ];
                  filesystem = {
                    bind_to_cwd = false;
                    follow_current_file.enabled = true;
                    use_libuv_file_watcher = true;
                  };
                  window = {
                    width = 30;
                    mappings = {
                      l = "open";
                      h = "close_node";
                      "<space>" = "none";
                      Y = {
                        "__unkeyed-1" = lib.nixvim.mkRaw ''
                          function(state)
                            local path = state.tree:get_node():get_id()
                            vim.fn.setreg("+", path, "c")
                          end
                        '';
                        desc = "Copy Path to Clipboard";
                      };
                      P = {
                        "__unkeyed-1" = "toggle_preview";
                        config.use_float = false;
                      };
                    };
                  };
                  default_component_configs = {
                    indent = {
                      with_expanders = true;
                      expander_collapsed = "";
                      expander_expanded = "";
                      expander_highlight = "NeoTreeExpander";
                    };
                    git_status.symbols = {
                      unstaged = "󰄱";
                      staged = "󰱒";
                    };
                  };
                };
              };

              schemastore = {
                enable = true;
                json.enable = true;
                yaml.enable = true;
              };

              render-markdown = {
                enable = true;
                settings = {
                  code = {
                    sign = false;
                    width = "block";
                    right_pad = 1;
                  };
                  heading = {
                    sign = false;
                    icons = [ ];
                  };
                  checkbox.enabled = false;
                };
              };

              markdown-preview.enable = true;

              lint = {
                enable = true;
                autoInstall.enable = true;
                lintersByFt = {
                  markdown = [ "markdownlint-cli2" ];
                  "markdown.mdx" = [ "markdownlint-cli2" ];
                  nix = [ "statix" ];
                };
              };

              lspconfig.enable = true;

              treesitter = {
                enable = true;
                highlight.enable = true;
                indent.enable = true;
                grammarPackages = with config.plugins.treesitter.package.builtGrammars; [
                  bash
                  diff
                  git_config
                  git_rebase
                  gitattributes
                  gitcommit
                  gitignore
                  json
                  json5
                  lua
                  markdown
                  markdown_inline
                  nix
                  query
                  toml
                  vim
                  vimdoc
                  yaml
                ];
              };

              conform-nvim = {
                enable = true;
                autoInstall.enable = true;
                settings = {
                  formatters_by_ft = {
                    nix = [ "nixfmt" ];
                    yaml = [ "yamlfmt" ];
                    json = [ "prettier" ];
                    jsonc = [ "prettier" ];
                    markdown = [
                      "prettier"
                      "markdownlint-cli2"
                    ];
                    "markdown.mdx" = [
                      "prettier"
                      "markdownlint-cli2"
                    ];
                  };
                  format_on_save = {
                    timeout_ms = 500;
                    lsp_format = "fallback";
                  };
                };
              };
            };

            lsp = {
              servers = {
                nixd = {
                  enable = true;
                  config.settings.formatting.command = [ "nixfmt" ];
                };
                marksman.enable = true;
                taplo.enable = true;
                jsonls = {
                  enable = true;
                  config.settings.json = {
                    format.enable = true;
                    validate.enable = true;
                  };
                };
                yamlls = {
                  enable = true;
                  config = {
                    capabilities.textDocument.foldingRange = {
                      dynamicRegistration = false;
                      lineFoldingOnly = true;
                    };
                    settings = {
                      redhat.telemetry.enabled = false;
                      yaml = {
                        keyOrdering = false;
                        format.enable = true;
                        validate = true;
                      };
                    };
                  };
                };
              };

              keymaps = [
                {
                  key = "gd";
                  lspBufAction = "definition";
                  options.desc = "Goto Definition";
                }
                {
                  key = "gr";
                  lspBufAction = "references";
                  options.desc = "References";
                }
                {
                  key = "gI";
                  lspBufAction = "implementation";
                  options.desc = "Goto Implementation";
                }
                {
                  key = "gy";
                  lspBufAction = "type_definition";
                  options.desc = "Goto Type Definition";
                }
                {
                  key = "K";
                  lspBufAction = "hover";
                  options.desc = "Hover";
                }
                {
                  key = "<leader>ca";
                  mode = [
                    "n"
                    "x"
                  ];
                  lspBufAction = "code_action";
                  options.desc = "Code Action";
                }
                {
                  key = "<leader>cr";
                  lspBufAction = "rename";
                  options.desc = "Rename";
                }
              ];
            };

            keymaps =
              lib.nixvim.keymaps.mkKeymaps
                {
                  mode = "n";
                  options = {
                    silent = true;
                    noremap = true;
                  };
                }
                [
                  {
                    key = "<C-S-f>";
                    action = projectAction ''require("fzf-lua").live_grep({ cwd = root })'';
                    options.desc = "Search Project";
                  }
                  {
                    key = "<C-h>";
                    action = "<cmd>bprevious<cr>";
                    options.desc = "Previous Buffer";
                  }
                  {
                    key = "<C-l>";
                    action = "<cmd>bnext<cr>";
                    options.desc = "Next Buffer";
                  }
                  {
                    key = "<C-S-h>";
                    action = "<C-w>h";
                    options.desc = "Focus Pane Left";
                  }
                  {
                    key = "<C-S-l>";
                    action = "<C-w>l";
                    options.desc = "Focus Pane Right";
                  }
                  {
                    key = "<C-S-k>";
                    action = "<C-w>k";
                    options.desc = "Focus Pane Up";
                  }
                  {
                    key = "<C-S-j>";
                    action = "<C-w>j";
                    options.desc = "Focus Pane Down";
                  }
                  {
                    key = "<C-S-t>";
                    action = luaAction ''
                      vim.cmd.enew()
                      vim.cmd.terminal()
                      vim.cmd.startinsert()
                    '';
                    options.desc = "New Center Terminal";
                  }
                  {
                    key = "X";
                    action = luaAction "MiniBufremove.delete()";
                    options.desc = "Delete Buffer";
                  }
                  {
                    key = "<S-h>";
                    action = "<cmd>bprevious<cr>";
                    options.desc = "Previous Buffer";
                  }
                  {
                    key = "<S-l>";
                    action = "<cmd>bnext<cr>";
                    options.desc = "Next Buffer";
                  }
                  {
                    key = "<leader>f";
                    action = projectAction ''require("fzf-lua").files({ cwd = root })'';
                    options.desc = "Find Files (Root Dir)";
                  }
                  {
                    key = "<leader>r";
                    action = projectAction ''require("fzf-lua").live_grep({ cwd = root })'';
                    options.desc = "Grep (Root Dir)";
                  }
                  {
                    key = "<leader>b";
                    action = luaAction ''require("fzf-lua").buffers({ sort_mru = true, sort_lastused = true })'';
                    options.desc = "Buffers";
                  }
                  {
                    key = "<leader>R";
                    action = luaAction ''require("fzf-lua").resume()'';
                    options.desc = "Resume Picker";
                  }
                  {
                    key = "<leader>d";
                    action = luaAction ''require("fzf-lua").diagnostics_workspace()'';
                    options.desc = "Diagnostics";
                  }
                  {
                    key = "<leader><space>";
                    action = projectAction ''require("fzf-lua").files({ cwd = root })'';
                    options.desc = "Find Files (Root Dir)";
                  }
                  {
                    key = "<leader>/";
                    action = projectAction ''require("fzf-lua").live_grep({ cwd = root })'';
                    options.desc = "Grep (Root Dir)";
                  }
                  {
                    key = "<leader>,";
                    action = luaAction ''require("fzf-lua").buffers({ sort_mru = true, sort_lastused = true })'';
                    options.desc = "Switch Buffer";
                  }
                  {
                    key = "<leader>ff";
                    action = projectAction ''require("fzf-lua").files({ cwd = root })'';
                    options.desc = "Find Files (Root Dir)";
                  }
                  {
                    key = "<leader>fF";
                    action = luaAction ''require("fzf-lua").files({ cwd = vim.uv.cwd() })'';
                    options.desc = "Find Files (cwd)";
                  }
                  {
                    key = "<leader>fg";
                    action = luaAction ''require("fzf-lua").git_files()'';
                    options.desc = "Find Git Files";
                  }
                  {
                    key = "<leader>fr";
                    action = luaAction ''require("fzf-lua").oldfiles()'';
                    options.desc = "Recent Files";
                  }
                  {
                    key = "<leader>sg";
                    action = projectAction ''require("fzf-lua").live_grep({ cwd = root })'';
                    options.desc = "Grep (Root Dir)";
                  }
                  {
                    key = "<leader>sd";
                    action = luaAction ''require("fzf-lua").diagnostics_workspace()'';
                    options.desc = "Diagnostics";
                  }
                  {
                    key = "<leader>sh";
                    action = luaAction ''require("fzf-lua").help_tags()'';
                    options.desc = "Help Pages";
                  }
                  {
                    key = "<leader>sk";
                    action = luaAction ''require("fzf-lua").keymaps()'';
                    options.desc = "Keymaps";
                  }
                  {
                    key = "<leader>gh";
                    action = luaAction "MiniExtra.pickers.git_hunks()";
                    options.desc = "Git Hunks";
                  }
                  {
                    key = "<leader>go";
                    action = luaAction ''require("mini.diff").toggle_overlay(0)'';
                    options.desc = "Toggle Diff Overlay";
                  }
                  {
                    key = "<leader>fm";
                    action = luaAction ''require("mini.files").open(vim.api.nvim_buf_get_name(0), true)'';
                    options.desc = "Mini Files (Current File)";
                  }
                  {
                    key = "<leader>fM";
                    action = luaAction ''require("mini.files").open(vim.uv.cwd(), true)'';
                    options.desc = "Mini Files (cwd)";
                  }
                  {
                    key = "<leader>fe";
                    action = projectAction ''require("neo-tree.command").execute({ toggle = true, dir = root })'';
                    options.desc = "Explorer Neo-tree (Root Dir)";
                  }
                  {
                    key = "<leader>fE";
                    action = luaAction ''require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })'';
                    options.desc = "Explorer Neo-tree (cwd)";
                  }
                  {
                    key = "<leader>e";
                    action = projectAction ''require("neo-tree.command").execute({ toggle = true, dir = root })'';
                    options.desc = "Explorer Neo-tree (Root Dir)";
                  }
                  {
                    key = "<leader>E";
                    action = luaAction ''require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })'';
                    options.desc = "Explorer Neo-tree (cwd)";
                  }
                  {
                    key = "<leader>ge";
                    action = luaAction ''require("neo-tree.command").execute({ source = "git_status", toggle = true })'';
                    options.desc = "Git Explorer";
                  }
                  {
                    key = "<leader>be";
                    action = luaAction ''require("neo-tree.command").execute({ source = "buffers", toggle = true })'';
                    options.desc = "Buffer Explorer";
                  }
                  {
                    key = "<leader>cp";
                    action = "<cmd>MarkdownPreviewToggle<cr>";
                    options.desc = "Markdown Preview";
                  }
                  {
                    key = "<leader>cf";
                    mode = [
                      "n"
                      "x"
                    ];
                    action = luaAction ''require("conform").format({ async = true, lsp_format = "fallback" })'';
                    options.desc = "Format";
                  }
                  {
                    key = "<leader>cd";
                    action = luaAction "vim.diagnostic.open_float()";
                    options.desc = "Line Diagnostics";
                  }
                  {
                    key = "]d";
                    action = luaAction "vim.diagnostic.jump({ count = vim.v.count1, float = true })";
                    options.desc = "Next Diagnostic";
                  }
                  {
                    key = "[d";
                    action = luaAction "vim.diagnostic.jump({ count = -vim.v.count1, float = true })";
                    options.desc = "Previous Diagnostic";
                  }
                  {
                    key = "s";
                    action = luaAction ''require("flash").jump()'';
                    options.desc = "Flash";
                  }
                  {
                    mode = "o";
                    key = "r";
                    action = luaAction ''require("flash").remote()'';
                    options.desc = "Remote Flash";
                  }
                ];

            autoCmd = [
              {
                event = "TextYankPost";
                callback = luaAction "vim.highlight.on_yank()";
                desc = "Highlight yanked text";
              }
            ];

            extraConfigLua = ''
              do
                local show_dotfiles = true

                vim.api.nvim_create_autocmd("User", {
                  pattern = "MiniFilesBufferCreate",
                  callback = function(args)
                    local function toggle_dotfiles()
                      show_dotfiles = not show_dotfiles
                      require("mini.files").refresh({
                        content = {
                          filter = show_dotfiles and function()
                            return true
                          end or function(entry)
                            return not vim.startswith(entry.name, ".")
                          end,
                        },
                      })
                    end

                    vim.keymap.set("n", "g.", toggle_dotfiles, {
                      buffer = args.data.buf_id,
                      desc = "Toggle hidden files",
                    })
                  end,
                })
              end
            '';
          }
        )
      ];
    };
  };
}
