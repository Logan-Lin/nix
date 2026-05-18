{ config, pkgs, inputs, ... }:

{
  imports = [
    ../modules/font.nix
    ../modules/terminal/zsh.nix
    ../modules/terminal/tmux.nix
    ../modules/terminal/nvim.nix
    ../modules/ssh.nix
    ../modules/git.nix
    ../modules/terminal/lazygit.nix
    ../modules/terminal/btop.nix
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
  ];
}
