{ config, pkgs, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;

  # Import the common NixOS home configuration
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
  ];

  # Any ThinkPad-specific home configurations can be added here
  # For example, laptop-specific aliases or scripts
}
