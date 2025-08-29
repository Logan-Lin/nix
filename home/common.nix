{ config, pkgs, nixvim, claude-code, firefox-addons, ... }:

{
  imports = [ 
    nixvim.homeManagerModules.nixvim
    ../modules/nvim.nix 
    ../modules/tmux.nix 
    ../modules/zsh.nix 
    ../modules/ssh.nix
    ../modules/git.nix
    ../modules/lazygit.nix
    ../modules/papis.nix
    ../modules/termscp.nix
    ../modules/rsync.nix
    ../modules/btop.nix
    ../modules/firefox.nix
    ../modules/ghostty.nix
    ../modules/syncthing.nix
    ../config/fonts.nix
    ../config/packages/common.nix
    ../config/packages/darwin.nix
    ../config/packages/dev.nix
    ../config/packages/productivity.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = "yanlin";
  home.homeDirectory = "/Users/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}