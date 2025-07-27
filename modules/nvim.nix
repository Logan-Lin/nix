{ pkgs, ... }:

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
    };

    # Extra plugins that don't have dedicated modules
    extraPlugins = with pkgs.vimPlugins; [
      vim-fugitive
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

      # System clipboard keymaps
      {
        mode = ["n" "v"];
        key = "<leader>y";
        action = "\"+y";
        options = { desc = "Copy to system clipboard"; };
      }
      {
        mode = "n";
        key = "<leader>p";
        action = "\"+p";
        options = { desc = "Paste from system clipboard"; };
      }
      {
        mode = "v";
        key = "<leader>p";
        action = "\"+p";
        options = { desc = "Replace selection with system clipboard"; };
      }

      # System integration
      {
        mode = "n";
        key = "<leader>o";
        action = ":silent !open %<CR>";
        options = { desc = "Open file with system default app"; };
      }
      {
        mode = "n";
        key = "<leader>f";
        action = ":silent !open -R %<CR>";
        options = { desc = "Show current file in Finder"; };
      }

      # Git keymaps (vim-fugitive)
      {
        mode = "n";
        key = "<leader>gs";
        action = ":Git<CR>";
        options = { desc = "Git status"; };
      }
      {
        mode = "n";
        key = "<leader>gd";
        action = ":Git diff<CR>";
        options = { desc = "Git diff"; };
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = ":Git commit<CR>";
        options = { desc = "Git commit"; };
      }
      {
        mode = "n";
        key = "<leader>gp";
        action = ":Git push<CR>";
        options = { desc = "Git push"; };
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
      -- Nvim-tree setup with filters
      require("nvim-tree").setup({
        filters = {
          dotfiles = true,      -- Hide dotfiles by default (H to toggle)
          git_ignored = false,  -- Show gitignored files by default (I to toggle)
          custom = {            -- Hide macOS system files
            ".DS_Store",
            ".AppleDouble",
            ".LSOverride",
            "._.*",
            ".DocumentRevisions-V100",
            ".fseventsd",
            ".Spotlight-V100",
            ".TemporaryItems",
            ".Trashes",
            ".VolumeIcon.icns",
            ".com.apple.timemachine.donotpresent",
          },
        },
      })
    '';
  };
}
