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

  # Always show GNOME top bar on Steam Deck
  gnome-custom.alwaysShowTopBar = true;

  # Disable Documents sync on Steam Deck (save space)
  syncthing-custom.enabledFolders = [ "Credentials" "Obsidian" ];

  # Enable Ghostty terminal with OSC-52 clipboard support
  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;
    fontSize = 12;
    windowMode = "maximized";
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
    vlc
  ];
}
