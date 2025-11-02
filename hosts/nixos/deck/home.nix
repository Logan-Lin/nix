{ config, pkgs, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;

  # Import the common NixOS home configuration
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/firefox.nix
    ../../../modules/ghostty.nix
    ../../../modules/gnome.nix
  ];

  # ThinkPad-specific applications
  home.packages = with pkgs; [
    obsidian
    keepassxc
    vlc
  ];
}
