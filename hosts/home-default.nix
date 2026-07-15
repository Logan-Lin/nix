# Cross-platform home default imported by every host on Linux and macOS.

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../modules/font.nix
    ../modules/zsh.nix
    ../modules/tmux.nix
    ../modules/nvim.nix
    ../modules/ssh.nix
    ../modules/git.nix
    ../modules/lazygit.nix
    ../modules/btop.nix
  ];

  home.username = "yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    coreutils
    curl
    wget
    gnumake
    gnused
    rsync
    bind
    inetutils
    netcat-gnu
    bandwhich
    ncdu
    fastfetch
    findutils
    yq-go
    python314
  ];
}
