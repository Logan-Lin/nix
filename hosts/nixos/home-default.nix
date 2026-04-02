{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../modules/terminal/nvim.nix
    ../../modules/terminal/tmux.nix 
    ../../modules/terminal/zsh.nix 
    ../../modules/ssh.nix
    ../../modules/git/home.nix
    ../../modules/git/lazygit.nix
    ../../modules/terminal/btop.nix
    ../../modules/font.nix
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
    gnumake
    rsync
    bind
    iputils
    inetutils
    netcat-gnu
    ncdu
    fastfetch
  ];
}
