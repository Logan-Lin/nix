{ config, pkgs, firefox-addons, plasma-manager, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;
  
  # Import the common NixOS home configuration
  imports = [ 
    ../home-default.nix 
    ../../../modules/firefox.nix
    ../../../modules/plasma.nix
    ../../../modules/syncthing.nix
    plasma-manager.homeModules.plasma-manager
  ];
  
  # Enable Firefox with NixOS-specific package
  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  # Any ThinkPad-specific home configurations can be added here
  # For example, laptop-specific aliases or scripts
  
  programs.zsh.shellAliases = {
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
    keepassxc
    obsidian
  ];
}
