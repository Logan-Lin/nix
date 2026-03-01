{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../../modules/nvim.nix 
    ../../modules/tmux.nix 
    ../../modules/zsh.nix 
    ../../modules/ssh.nix
    ../../modules/git/home.nix
    ../../modules/git/lazygit.nix
    ../../modules/btop.nix
    ../../modules/font.nix
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
