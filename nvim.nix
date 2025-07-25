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
      vim.opt.termguicolors = true

      -- Enable filetype detection and syntax
      vim.cmd('filetype on')
      vim.cmd('filetype plugin on')
      vim.cmd('filetype indent on')
      vim.cmd('syntax enable')

      -- Leader key
      vim.g.mapleader = " "

      -- Set gruvbox colorscheme to match lualine theme
      vim.opt.background = "dark"
      vim.cmd('colorscheme gruvbox')

      -- Nvim-tree setup
      require("nvim-tree").setup({})
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

      -- Lualine setup
      require('lualine').setup({
        options = {
          theme = 'gruvbox_dark',
          component_separators = { left = '|', right = '|'},
          section_separators = { left = ' ', right = ' '},
        },
      })

      -- Basic keymaps
      vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
      vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
    '';
  };
}
