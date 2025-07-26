{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      nvim-tree-lua
      nvim-treesitter.withAllGrammars
      lualine-nvim
      nvim-web-devicons
      gruvbox-nvim
      vim-fugitive
    ];
    extraLuaConfig = ''
      -- Basic settings
      vim.opt.number = true
      vim.opt.relativenumber = false
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.linebreak = true      -- Don't break words when wrapping
      vim.opt.breakindent = true    -- Preserve indentation when wrapping
      vim.opt.termguicolors = true

      -- Enable filetype detection and syntax
      vim.cmd('filetype on')
      vim.cmd('filetype plugin on')
      vim.cmd('filetype indent on')
      vim.cmd('syntax enable')

      -- Leader key
      vim.g.mapleader = " "

      -- Configure gruvbox with hard contrast for darker background
      require("gruvbox").setup({
        contrast = "hard", -- Makes background much darker (#1d2021 instead of #282828)
      })
      vim.opt.background = "dark"
      vim.cmd('colorscheme gruvbox')

      -- Nvim-tree setup
      require("nvim-tree").setup({
        filters = {
          dotfiles = true,      -- Hide dotfiles by default (Ctrl+H to toggle)
          git_ignored = false,  -- Show gitignored files by default (Ctrl+I to toggle)
        },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

      -- Treesitter setup
      require('nvim-treesitter.configs').setup({
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
        indent = {
          enable = true,
        },
        ensure_installed = {}, -- Managed by Nix
        auto_install = false,
      })

      -- Lualine setup with gruvbox theme
      require('lualine').setup({
        options = {
          theme = 'gruvbox_dark',
          component_separators = { left = '|', right = '|'},
          section_separators = { left = ' ', right = ' '},
        },
        sections = {
          lualine_c = { { 'filename', path = 1 } },
        },
      })

      -- Basic keymaps
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
      vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
      
      -- System clipboard keymaps
      vim.keymap.set({"n", "v"}, "<leader>y", "\"+y", { desc = "Copy to system clipboard" })
      vim.keymap.set("n", "<leader>p", "\"+p", { desc = "Paste from system clipboard" })
      vim.keymap.set("v", "<leader>p", "\"+p", { desc = "Replace selection with system clipboard" })
      
      -- Git keymaps (vim-fugitive)
      vim.keymap.set("n", "<leader>gs", ":Git<CR>", { desc = "Git status" })
      vim.keymap.set("n", "<leader>gd", ":Git diff<CR>", { desc = "Git diff" })
      vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
      vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
    '';
  };
}
