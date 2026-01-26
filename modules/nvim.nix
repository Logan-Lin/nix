{ pkgs, lib, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    # scowl provides English word lists for completion on NixOS
    extraPackages = [ pkgs.scowl ];

    # Global settings
    globals.mapleader = " ";

    # Vim options
    opts = {
      number = true;
      relativenumber = false;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;
      wrap = true;
      linebreak = true;      # Don't break words when wrapping
      breakindent = true;    # Preserve indentation when wrapping
      termguicolors = true;
      autoread = true;       # Automatically reload files when changed externally
      clipboard = "unnamedplus";  # Use system clipboard by default
    };

    # Enable filetype detection
    viAlias = true;
    vimAlias = true;

    # Gruvbox colorscheme with hard contrast
    colorschemes.gruvbox = {
      enable = true;
      settings = {
        contrast = "hard";  # Makes background much darker (#1d2021 instead of #282828)
        background = "dark";
      };
    };

    # Plugins
    plugins = {

      bufferline = {
        enable = true;
        settings = {
          options = {
            separator_style = [ "" "" ];  # Remove gaps between tabs
          };
        };
      };
      gitsigns.enable = true;
      indent-blankline = {
        enable = true;
        settings = {
          indent = {
            char = "▏";  # Thinner vertical line
          };
          scope = {
            enabled = false;  # Disable scope highlighting
          };
        };
      };

      # Syntax highlighting
      treesitter = {
        enable = true;
        settings = {
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = true;
          };
          indent = {
            enable = true;
          };
          ensure_installed = [];  # Managed by Nix
          auto_install = false;
        };
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash c cpp css dockerfile go html javascript json lua markdown nix python rust typescript yaml
        ];
      };

      # Status line with gruvbox theme and relative paths
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

      # Web dev icons
      web-devicons = {
        enable = true;
      };

      # Basic auto-completion
      cmp = {
        enable = true;
        autoEnableSources = true;
        
        settings = {
          sources = [
            { name = "buffer"; }     # Words from open buffers
            { name = "path"; }       # File system paths
            { name = "dictionary"; keyword_length = 2; } # English dictionary words
          ];
          
          mapping = {
            "<C-Space>" = "cmp.mapping.complete()";          # Trigger completion manually
            "<C-e>" = "cmp.mapping.close()";                 # Close completion menu
            "<CR>" = "cmp.mapping.confirm({ select = true })"; # Accept selected completion
            "<Tab>" = "cmp.mapping.select_next_item()";      # Navigate down in menu
            "<S-Tab>" = "cmp.mapping.select_prev_item()";    # Navigate up in menu
          };
        };
      };

      # Telescope - Fuzzy finder
      telescope = {
        enable = true;
        keymaps = {
          # Find files using Telescope command-line sugar
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
              "--no-ignore"
            ];
            file_ignore_patterns = [
              "^.git/"
              "^node_modules/"
              ".DS_Store"
            ];
            layout_config = {
              prompt_position = "bottom";
              horizontal = {
                preview_width = 0.55;
              };
            };
          };
          pickers = {
            find_files = {
              hidden = true;
              no_ignore = true;
            };
          };
        };
      };

      auto-session.enable = true;

      render-markdown = {
        enable = true;
        settings = {
          enabled = false;  # Disabled by default
        };
      };

      neo-tree = {
        enable = true;
        settings = {
          default_component_configs = {
            file_size = {
              enabled = true;
              required_width = 40;
            };
            type = {
              enabled = false;
            };
            last_modified = {
              enabled = true;
              required_width = 68;
            };
          };
          filesystem = {
            follow_current_file = {
              enabled = true;
              leave_dirs_open = true;
            };
            filtered_items = {
              hide_dotfiles = false;
              hide_gitignored = false;
              hide_hidden = false;
            };
          };
          window = {
            position = "float";
            popup = {
              size = {
                width.__raw = "math.min(math.max(86, math.floor(vim.o.columns * 0.5)), math.floor(vim.o.columns * 0.85))";
                height = "75%";
              };
              border = "rounded";
            };
            mappings = {
              # Keep: navigation & file operations
              "." = "set_root";
              "<bs>" = "navigate_up";
              "<cr>" = "open";
              "<esc>" = "cancel";
              q = "close_window";
              "?" = "show_help";
              a = "add";
              r = "rename";
              b = "rename_basename";
              m = "none";
              c = "copy_to_clipboard";
              y = "none";
              x = "cut_to_clipboard";
              p = "paste_from_clipboard";
              d = "delete";
              o = { command = "system_open"; nowait = true; };
              # Disable everything else
              "#" = "none";
              "/" = "none";
              "<" = "none";
              ">" = "none";
              "<C-b>" = "none";
              "<C-f>" = "none";
              "<C-r>" = "none";
              "<C-x>" = "none";
              "<space>" = "none";
              A = "none";
              C = "none";
              D = "none";
              H = "toggle_hidden";
              P = "none";
              R = "none";
              S = "none";
              "[g" = "none";
              "]g" = "none";
              e = "none";
              f = { command = "show_in_finder"; nowait = true; };
              i = "none";
              l = "none";
              s = "none";
              t = "none";
              w = "none";
              z = "none";
              oc = "none";
              od = "none";
              og = "none";
              om = "none";
              on = "none";
              os = "none";
              ot = "none";
            };
          };
          commands = {
            system_open.__raw = ''
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                ${if pkgs.stdenv.isDarwin then
                  ''vim.fn.system('open ' .. vim.fn.shellescape(path))''
                else
                  ''vim.fn.system('xdg-open ' .. vim.fn.shellescape(path))''}
              end
            '';
            show_in_finder.__raw = ''
              function(state)
                local node = state.tree:get_node()
                local path = node:get_id()
                ${if pkgs.stdenv.isDarwin then
                  ''vim.fn.system('open -R ' .. vim.fn.shellescape(path))''
                else
                  ''vim.fn.system('thunar ' .. vim.fn.shellescape(vim.fn.fnamemodify(path, ':h')) .. ' &')''}
              end
            '';
          };
        };
      };
    };

    # Extra plugins that don't have dedicated modules
    extraPlugins = with pkgs.vimPlugins; [
      vim-fugitive
      cmp-dictionary
      plenary-nvim
    ];

    # Keymaps
    keymaps = [
      # File explorer (neo-tree)
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree toggle reveal<CR>";
        options = { desc = "Toggle file explorer"; };
      }

      # Markdown rendering
      {
        mode = "n";
        key = "<leader>m";
        action = ":RenderMarkdown toggle<CR>";
        options = { desc = "Toggle markdown rendering"; };
      }
      # Basic keymaps
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

      # Buffer/Tab navigation
      {
        mode = "n";
        key = "<S-h>";
        action = ":BufferLineCyclePrev<CR>";
        options = { desc = "Previous buffer"; };
      }
      {
        mode = "n";
        key = "<S-l>";
        action = ":BufferLineCycleNext<CR>";
        options = { desc = "Next buffer"; };
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":bp|bd #<CR>";
        options = { desc = "Close current buffer"; };
      }
      {
        mode = "n";
        key = "<leader>X";
        action = ":lua close_other_buffers()<CR>";
        options = { desc = "Close all buffers except current"; };
      }

    ];

    # Additional Lua configuration for plugins that need custom setup
    extraConfigLua = ''
      -- Dictionary completion setup
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        require("cmp_dictionary").setup({
          paths = { "/usr/share/dict/words" },  -- Standard dictionary path on macOS
          exact_length = 2,                     -- Minimum length before completion
          first_case_insensitive = true,        -- Case insensitive matching
        })
      ''}
      ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
        require("cmp_dictionary").setup({
          paths = { "${pkgs.scowl}/share/dict/wamerican.txt" },  -- Nix-provided dictionary on NixOS
          exact_length = 2,                                       -- Minimum length before completion
          first_case_insensitive = true,                          -- Case insensitive matching
        })
      ''}

      -- Telescope setup for better file finding
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
      -- OSC-52 clipboard integration (matches tmux setup, works with Ghostty)
      -- This enables clipboard functionality across SSH, tmux, and multi-platform
      -- Only enabled on Linux; macOS uses native clipboard with "unnamedplus"
      ${lib.optionalString (!pkgs.stdenv.isDarwin) ''
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
      ''}

      -- Close all buffers except current (preserving special buffers)
      function close_other_buffers()
        local current_buf = vim.api.nvim_get_current_buf()
        local buffers = vim.api.nvim_list_bufs()

        for _, buf in ipairs(buffers) do
          if buf ~= current_buf and vim.api.nvim_buf_is_valid(buf) then
            local buftype = vim.api.nvim_buf_get_option(buf, 'buftype')

            -- Skip special buffers (terminals, quickfix, etc.)
            if buftype == "" then
              vim.api.nvim_buf_delete(buf, { force = false })
            end
          end
        end
      end

      -- Disable italic for code blocks and strings
      vim.api.nvim_set_hl(0, "@markup.raw", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.block", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { italic = false })
      vim.api.nvim_set_hl(0, "String", { fg = "#b8bb26", italic = false })

    '';
  };
}
