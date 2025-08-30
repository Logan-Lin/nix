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
  ];

  nixpkgs.config.allowUnfree = true;

  home.username = "yanlin";
  home.homeDirectory = "/Users/yanlin";
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

    # macOS-specific GUI applications
    maccy          # Clipboard manager (macOS-only)
    appcleaner     # Application uninstaller (macOS-only)
    iina           # Media player (macOS-optimized)
    hidden-bar     # Menu bar organizer (macOS-only)

    # Development and build tools
    texlive.combined.scheme-full
    python312
    uv
    claude-code.packages.aarch64-darwin.claude-code
    lazysql
    sqlite

    # Productivity apps
    keepassxc      # Password manager (Linux/Windows/macOS)
  ];
}
