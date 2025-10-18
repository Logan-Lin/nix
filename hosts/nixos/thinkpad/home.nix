{ config, pkgs, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;

  # Import the common NixOS home configuration
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/ghostty.nix
    ../../../modules/tex.nix
  ];

  # Enable Ghostty terminal with NixOS package
  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;  # Install via nix on NixOS
    fontSize = 11;
    windowMode = "maximized";
  };

  # Any ThinkPad-specific home configurations can be added here
  # For example, laptop-specific aliases or scripts
}
