{ config, pkgs, nixvim, claude-code, ... }:

{
  imports = [ 
    nixvim.homeModules.nixvim
    ../../modules/nvim.nix 
    ../../modules/tmux.nix 
    ../../modules/zsh.nix 
    ../../modules/ssh.nix
    ../../modules/git.nix
    ../../modules/lazygit.nix
    ../../modules/termscp.nix
    ../../modules/rsync.nix
    ../../modules/btop.nix
    ../../modules/syncthing.nix
    ../../config/fonts.nix
  ];

  home.username = "yanlin";
  home.homeDirectory = "/home/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Network and file transfer
    lftp
    httpie
    openssh
    gnumake
    
    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
    fastfetch

    # Development and build tools
    python312
    uv
    claude-code.packages.x86_64-linux.claude-code
    lazysql
    sqlite
  ];
}
