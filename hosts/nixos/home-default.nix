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
