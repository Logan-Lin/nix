{ pkgs, lib, ... }:

{
  programs.nixvim = {
    enable = true;
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

      bufferline = {
        enable = true;
        settings = {
          options = {
            separator_style = [ "" "" ];
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
          bash c cpp css dockerfile go html javascript json lua markdown nix python rust typescript yaml latex
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

      auto-session.enable = true;

      todo-comments.enable = true;

      render-markdown = {
        enable = true;
        settings = {
          enabled = false;
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
              enabled = false;
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
                width = 76;
                height = "85%";
              };
              border = "rounded";
            };
            mappings = {
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
              f = { command = "show_in_finder"; nowait = true; };
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
              S = "none";
              "[g" = "none";
              "]g" = "none";
              e = "none";
              l = "none";
              s = "none";
              t = "none";
              w = "none";
              z = "none";
              Z = "close_all_nodes";
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

    extraPlugins = with pkgs.vimPlugins; [
      vim-fugitive
      plenary-nvim
    ];

    keymaps = [
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree toggle reveal<CR>";
        options = { desc = "Toggle file explorer"; };
      }
      {
        mode = "n";
        key = "<leader>m";
        action = ":RenderMarkdown toggle<CR>";
        options = { desc = "Toggle markdown rendering"; };
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

      vim.api.nvim_set_hl(0, "@markup.raw", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.block", { italic = false })
      vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { italic = false })
      vim.api.nvim_set_hl(0, "String", { fg = "#b8bb26", italic = false })

    '';
  };
}
