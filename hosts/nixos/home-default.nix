# NixOS platform default for the home-manager configuration.
# Imports the cross-platform home default and layers on the settings specific to Linux.

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../home-default.nix
  ];

  home.homeDirectory = "/home/yanlin";

  programs.zsh.shellAliases = {
      oss = "sudo nixos-rebuild switch --flake ~/.config/nix#$(hostname)";
  };

  home.packages = with pkgs; [
    iputils
  ];
}
