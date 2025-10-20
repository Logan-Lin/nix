{ config, pkgs, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;

  # Import the common NixOS home configuration
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/gnome.nix
    ../../../modules/firefox.nix
  ];

  # Enable GNOME configuration
  programs.gnome-custom = {
    enable = true;
  };

  # Enable Firefox browser
  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  # ThinkPad-specific applications
  home.packages = with pkgs; [
    obsidian
    keepassxc
  ];
}
