{ pkgs, lib, ... }:

{
  programs.nixvim = {
    enable = true;
    defaultEditor = true;

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
      wrap = false;
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

      bufferline.enable = true;
      gitsigns.enable = true;
      indent-blankline.enable = true;

      # File explorer
      nvim-tree = {
        enable = true;
        # NixVim nvim-tree uses extraConfig for detailed settings
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

      # Markdown rendering
      render-markdown = {
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
    };

    # Extra plugins that don't have dedicated modules
    extraPlugins = with pkgs.vimPlugins; [
      vim-fugitive
      cmp-dictionary
      plenary-nvim  # Required dependency for telescope
    ];

    # Keymaps
    keymaps = [
      # File explorer
      {
        mode = "n";
        key = "<leader>e";
        action = ":NvimTreeToggle<CR>";
        options = { desc = "Toggle file explorer"; };
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

      # System integration
      {
        mode = "n";
        key = "<leader>o";
        action = ":lua open_file_with_system_app()<CR>";
        options = { desc = "Open file with system default app"; };
      }
      {
        mode = "n";
        key = "<leader>f";
        action = ":lua show_file_in_finder()<CR>";
        options = { desc = "Show current file in Finder"; };
      }

      # Markdown rendering
      {
        mode = "n";
        key = "<leader>md";
        action = ":RenderMarkdown toggle<CR>";
        options = { desc = "Toggle markdown rendering"; };
      }
    ];

    # Additional Lua configuration for plugins that need custom setup
    extraConfigLua = ''
      -- Nvim-tree setup with filters and auto-sync
      require("nvim-tree").setup({
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
          ignore_list = {},
        },
        filters = {
          dotfiles = true,      -- Hide dotfiles by default (H to toggle)
          git_ignored = true,  -- Show gitignored files by default (I to toggle)
          custom = {            -- Hide macOS system files
            ".DS_Store",
          },
        },
        view = {
          width = 30,
          side = "left",
        },
        renderer = {
          highlight_opened_files = "all",
          highlight_modified = "all",
        },
      })

      -- Dictionary completion setup (macOS only)
      ${lib.optionalString pkgs.stdenv.isDarwin ''
        require("cmp_dictionary").setup({
          paths = { "/usr/share/dict/words" },  -- Standard dictionary path on macOS
          exact_length = 2,                     -- Minimum length before completion
          first_case_insensitive = true,        -- Case insensitive matching
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
        }
      }

      -- Unicode-safe file operations
      function open_file_with_system_app()
        local filepath = vim.fn.expand('%:p')
        if filepath ~= "" then
          local escaped_path = vim.fn.shellescape(filepath)
          ${if pkgs.stdenv.isDarwin then 
            "vim.fn.system('open ' .. escaped_path)" 
          else 
            "vim.fn.system('xdg-open ' .. escaped_path)"}
        else
          print("No file to open")
        end
      end

      ${lib.optionalString pkgs.stdenv.isDarwin ''
        function show_file_in_finder()
          local filepath = vim.fn.expand('%:p')
          if filepath ~= "" then
            local escaped_path = vim.fn.shellescape(filepath)
            vim.fn.system('open -R ' .. escaped_path)
          else
            print("No file to show")
          end
        end
      ''}
    '';
  };
}
