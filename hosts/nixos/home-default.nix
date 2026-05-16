{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/font.nix
    ../../modules/terminal/zsh.nix 
    ../../modules/terminal/tmux.nix 
    ../../modules/terminal/nvim.nix
    ../../modules/ssh.nix
    ../../modules/git.nix
    ../../modules/terminal/lazygit.nix
    ../../modules/terminal/btop.nix
  ];

  home.username = "yanlin";
  home.homeDirectory = "/home/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  programs.zsh.shellAliases = {
      oss = "sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname)";
  };

  home.packages = with pkgs; [
    curl
    wget
    gnumake
    gnused
    rsync
    bind
    iputils
    inetutils
    netcat-gnu
    bandwhich
    ncdu
    fastfetch
    findutils
    yq-go
  ];
}
