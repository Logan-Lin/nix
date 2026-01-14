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
    ../../modules/rsync.nix
    ../../modules/btop.nix
    ../../modules/claude-code.nix
    ../../modules/transcode.nix
    ../../modules/fonts.nix
    ../../modules/env.nix
  ];

  home.username = "yanlin";
  home.homeDirectory = "/home/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # nixOS-specific alias
  programs.zsh.shellAliases = {
      oss = "sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname)";

      # Network monitoring aliases (no sudo needed - NixOS module handles permissions)
      bw = "bandwhich";
      bw-raw = "bandwhich --raw";
      bw-dns = "bandwhich --show-dns";
  };

  home.packages = with pkgs; [
    # Network and file transfer
    lftp
    httpie
    openssh
    gnumake

    # Network diagnostic tools
    bind           # DNS utilities (dig, nslookup, mdig)
    iputils        # Core network tools (ping, traceroute)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility
    curl           # HTTP client
    wget           # Web downloader

    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
    fastfetch
    coreutils      # GNU core utilities (base64, etc.)
    bzip2
    ffmpeg
    pdftk

    # Development and build tools
    python312
    uv
    lazysql
    sqlite
  ];
}
