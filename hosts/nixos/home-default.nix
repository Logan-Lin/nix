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
  };

  home.packages = with pkgs; [
    httpie
    gnumake
    rsync
    bind           # DNS utilities (dig, nslookup, mdig)
    iputils        # Core network tools (ping, traceroute)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility
    ncdu
    delta
    fastfetch
  ];
}
