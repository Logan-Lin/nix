{ pkgs, lib, inputs, ... }:

{
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    nixpkgs.source = inputs.nixpkgs;
    defaultEditor = true;
    globals.mapleader = " ";

    opts = {
      number = true;
      relativenumber = false;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;
      wrap = true;
      linebreak = true;
      breakindent = true;
      termguicolors = true;
      signcolumn = "yes";
      autoread = true;
      clipboard = "unnamedplus";
      cmdheight = 0;
      showmode = false;
    };

    viAlias = true;
    vimAlias = true;

    colorschemes.gruvbox = {
      enable = true;
      settings = {
        contrast = "hard";
        background = "dark";
      };
    };

    plugins = {

      mini-tabline = {
        enable = true;
        settings = {
          show_icons = false;
          set_vim_settings = true;
          tabpage_section = "none";
          format.__raw = ''
            function(_, label)
              local max = 30
              if vim.fn.strchars(label) > max then
                label = "…" .. vim.fn.strcharpart(label, vim.fn.strchars(label) - max + 1)
              end
              return " " ..  label .. " "
            end
          '';
        };
      };
      noice = {
        enable = true;
        settings = {
          cmdline = {
            view = "cmdline_popup";
            format = {
              cmdline = { pattern = "^:"; icon = ":"; lang = "vim"; };
              search_down = { kind = "search"; pattern = "^/"; icon = "/"; lang = "regex"; };
              search_up = { kind = "search"; pattern = "^%?"; icon = "?"; lang = "regex"; };
            };
          };
          messages = {
            enabled = true;
            view = "mini";
            view_error = "mini";
            view_warn = "mini";
            view_history = "mini";
            view_search = "mini";
          };
          popupmenu.enabled = true;
          notify = {
            enabled = true;
            view = "mini";
          };
          lsp = {
            progress.enabled = false;
            hover.enabled = false;
            signature.enabled = false;
            message.enabled = false;
          };
          presets = {
            bottom_search = false;
            command_palette = false;
            long_message_to_split = true;
            inc_rename = false;
            lsp_doc_border = false;
          };
          routes = [
            { filter = { event = "msg_showmode"; }; view = "mini"; }
          ];
          views = {
            mini = {
              timeout = 4000;
              reverse = false;
              border.style = "none";
              size = {
                max_height = 7;
                max_width = 80;
              };
              win_options = {
                winblend = 0;
                wrap = true;
                linebreak = true;
                winhighlight = {
                  Normal = "NormalFloat";
                  FloatBorder = "FloatBorder";
                };
              };
            };
          };
        };
      };
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "▏";
          };
          scope = {
            enabled = false;
          };
        };
      };

      treesitter = {
        enable = true;
        settings = {
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = false;
          };
          indent = {
            enable = true;
          };
          ensure_installed = [];
          auto_install = false;
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash c cpp css dockerfile go html javascript json lua markdown markdown-inline nix python rust typescript yaml latex
        ];
      };

      lualine = {
        enable = true;
        settings = {
          options = {
            theme = "gruvbox_dark";
            component_separators = { left = "|"; right = "|"; };
            section_separators = { left = " "; right = " "; };
          };
          sections = {
            lualine_c = [{ __unkeyed-1 = "filename"; path = 1; }];
          };
        };
      };

      web-devicons = {
        enable = true;
      };

      telescope = {
        enable = true;
        keymaps = {
          "<leader>t" = "find_files";
          "<leader>g" = "live_grep";
        };
        settings = {
          defaults = {
            vimgrep_arguments = [
              "rg"
              "--color=never"
              "--no-heading"
              "--with-filename"
              "--line-number"
              "--column"
              "--smart-case"
              "--hidden"
            ];
            file_ignore_patterns = [
              "%.git/"
            ];
            layout_config = {
              prompt_position = "bottom";
              width = 160;
              horizontal = {
                preview_width = 0.55;
              };
            };
          };
          pickers = {
            find_files = {
              hidden = true;
            };
          };
        };
      };

      todo-comments.enable = true;

      aerial = {
        enable = true;
        settings = {
          backends = [ "treesitter" "markdown" "man" ];
          attach_mode = "global";
          close_on_select = true;
          show_guides = true;
          keymaps = {
            "<Esc>" = "actions.close";
          };
          layout = {
            default_direction = "float";
            placement = "window";
            win_opts = {
              winhighlight = "NormalFloat:Normal,SignColumn:Normal,FoldColumn:Normal,EndOfBuffer:Normal";
              signcolumn = "yes:1";
            };
          };
          float = {
            border = "rounded";
            relative = "editor";
            override.__raw = ''
              function(conf, _)
                local width = 76
                local height = math.floor(vim.o.lines * 0.85)
                conf.width = width
                conf.height = height
                conf.row = math.floor((vim.o.lines - height) / 2) - 1
                conf.col = math.floor((vim.o.columns - width) / 2)
                return conf
              end
            '';
          };
        };
      };

      nvim-tree = {
        enable = true;
        settings = {
          disable_netrw = true;
          hijack_netrw = true;
          respect_buf_cwd = true;
          sync_root_with_cwd = true;
          view = {
            width = 76;
            float = {
              enable = true;
              open_win_config.__raw = ''
                function() return _G.nvim_tree_float_config() end
              '';
            };
          };
          renderer = {
            group_empty = true;
            indent_markers.enable = true;
            highlight_opened_files = "name";
          };
          update_focused_file = {
            enable = true;
            update_root = false;
          };
          filters = {
            dotfiles = false;
            git_ignored = false;
            custom = [ ".DS_Store" ".localized" ];
          };
          actions = {
            open_file = {
              quit_on_open = true;
            };
          };
          on_attach.__raw = ''
            function(bufnr)
              local api = require("nvim-tree.api")
              api.config.mappings.default_on_attach(bufnr)

              local function opts(desc)
                return { desc = "nvim-tree: " .. desc, buffer = bufnr,
                         noremap = true, silent = true, nowait = true }
              end

              vim.keymap.set("n", "f", function()
                local node = api.tree.get_node_under_cursor()
                if not node then return end
                ${if pkgs.stdenv.isDarwin
                  then ''vim.fn.jobstart({ "open", "-R", node.absolute_path }, { detach = true })''
                  else ''vim.fn.jobstart({ "xdg-open", vim.fn.fnamemodify(node.absolute_path, ":h") }, { detach = true })''}
              end, opts("Reveal in Finder"))

              vim.keymap.set("n", "o", api.node.run.system, opts("System Open"))
              vim.keymap.set("n", "<esc>", api.tree.close, opts("Close"))
              vim.keymap.set("n", "y", api.fs.copy.relative_path, opts("Copy Relative Path"))
              vim.keymap.set("n", "Y", api.fs.copy.absolute_path, opts("Copy Absolute Path"))
            end
          '';
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = ":NvimTreeFindFileToggle<CR>";
        options = { desc = "Toggle file tree"; };
      }
      {
        mode = "n";
        key = "<leader>o";
        action = ":AerialToggle<CR>";
        options = { desc = "Toggle outline"; };
      }
      {
        mode = "n";
        key = "<leader>O";
        action = ":Telescope aerial<CR>";
        options = { desc = "Search symbols via Telescope"; };
      }
      {
        mode = "n";
        key = "<leader>w";
        action = ":w<CR>";
        options = { desc = "Save file"; };
      }
      {
        mode = "n";
        key = "<leader>q";
        action = ":q<CR>";
        options = { desc = "Quit"; };
      }
      {
        mode = "n";
        key = "<leader>r";
        action = ":e<CR>";
        options = { desc = "Refresh"; };
      }
      {
        mode = "n";
        key = "<S-h>";
        action = ":bprevious<CR>";
        options = { desc = "Previous buffer"; };
      }
      {
        mode = "n";
        key = "<S-l>";
        action = ":bnext<CR>";
        options = { desc = "Next buffer"; };
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":lua close_current_buffer()<CR>";
        options = { desc = "Close current buffer"; };
      }
      {
        mode = "n";
        key = "<leader>X";
        action = ":lua close_other_buffers()<CR>";
        options = { desc = "Close all buffers except current"; };
      }
    ];

    extraConfigLua = ''
      local telescope = require('telescope')
      local actions = require('telescope.actions')

      telescope.setup{
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            }
          }
        },
      }
      telescope.load_extension('aerial')

      vim.treesitter.language.register('latex', 'plaintex')

      local function ssh_session_active()
        if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.SSH_CLIENT then
          return true
        end
        if vim.env.TMUX then
          local out = vim.fn.system({ "tmux", "show-environment", "SSH_CONNECTION" })
          if vim.v.shell_error == 0 and out:match("^SSH_CONNECTION=") then
            return true
          end
        end
        return false
      end

      if ssh_session_active() then
        vim.g.clipboard = {
          name = 'OSC 52',
          copy = {
            ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
            ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
          },
          paste = {
            ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
            ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
          },
        }
      end

      function _G.nvim_tree_float_config()
        local width = 76
        local height = math.floor(vim.o.lines * 0.85)
        return {
          relative = "editor",
          border = "rounded",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2) - 1,
          col = math.floor((vim.o.columns - width) / 2),
        }
      end

      vim.api.nvim_create_autocmd("VimResized", {
        callback = function()
          for _, winid in ipairs(vim.api.nvim_list_wins()) do
            local bufnr = vim.api.nvim_win_get_buf(winid)
            if vim.bo[bufnr].filetype == "NvimTree" then
              vim.api.nvim_win_set_config(winid, _G.nvim_tree_float_config())
            end
          end
        end,
      })

      function close_current_buffer()
        local current_buf = vim.api.nvim_get_current_buf()
        local listed_bufs = vim.tbl_filter(function(buf)
          return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
        end, vim.api.nvim_list_bufs())

        if #listed_bufs > 1 then
          vim.cmd("bprevious")
        else
          vim.cmd("enew")
        end
        vim.api.nvim_buf_delete(current_buf, { force = false })
      end

      function close_other_buffers()
        local current_buf = vim.api.nvim_get_current_buf()
        local buffers = vim.api.nvim_list_bufs()

        for _, buf in ipairs(buffers) do
          if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) then
            local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')

            if buftype == "" then
              vim.api.nvim_buf_delete(buf, { force = false })
            end
          end
        end
      end

      vim.api.nvim_set_hl(0, "MiniTablineCurrent",         { bg = "#1d2021", fg = "#ebdbb2", bold = true })
      vim.api.nvim_set_hl(0, "MiniTablineVisible",         { bg = "#3c3836", fg = "#a89984" })
      vim.api.nvim_set_hl(0, "MiniTablineHidden",          { bg = "#3c3836", fg = "#a89984" })
      vim.api.nvim_set_hl(0, "MiniTablineModifiedCurrent", { bg = "#1d2021", fg = "#fe8019", bold = true })
      vim.api.nvim_set_hl(0, "MiniTablineModifiedVisible", { bg = "#3c3836", fg = "#fe8019" })
      vim.api.nvim_set_hl(0, "MiniTablineModifiedHidden",  { bg = "#3c3836", fg = "#fe8019" })
      vim.api.nvim_set_hl(0, "MiniTablineFill",            { bg = "#3c3836" })

      vim.api.nvim_set_hl(0, "@markup.raw", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.block", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { italic = false })
      vim.api.nvim_set_hl(0, "String", { fg = "#b8bb26", italic = false })

      vim.api.nvim_set_hl(0, "NvimTreeNormal", { link = "Normal" })
      vim.api.nvim_set_hl(0, "NvimTreeNormalFloat", { link = "Normal" })
      vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { link = "Normal" })
      vim.api.nvim_set_hl(0, "NvimTreeCutHL", { fg = "#fb4934", italic = true })
      vim.api.nvim_set_hl(0, "NvimTreeCopiedHL", { fg = "#fabd2f", italic = true })

      do
        local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
        local fb_fg = vim.api.nvim_get_hl(0, { name = "FloatBorder" }).fg
        vim.api.nvim_set_hl(0, "FloatBorder", { fg = fb_fg, bg = normal_bg })
      end

    '';
  };
}
