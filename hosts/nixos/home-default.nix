{ config, pkgs, nixvim, ... }:

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
    ../../modules/font/home.nix
  ];

  home.username = "yanlin";
  home.homeDirectory = "/home/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

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
    gnumake

    # Network diagnostic tools
    bind           # DNS utilities (dig, nslookup, mdig)
    iputils        # Core network tools (ping, traceroute)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility

    # Command-line utilities
    ncdu
    delta
    fastfetch
  ];
}
