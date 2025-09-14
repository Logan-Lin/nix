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
    ../../../modules/ghostty.nix
    plasma-manager.homeModules.plasma-manager
  ];
  
  # Enable Firefox with NixOS-specific package
  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  # Enable Ghostty terminal with NixOS package
  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;  # Install via nix on NixOS
    fontSize = 11;
    windowMode = "maximized";
  };

  # Any ThinkPad-specific home configurations can be added here
  # For example, laptop-specific aliases or scripts
  
  programs.zsh.shellAliases = {
    # Disk health monitoring
    smart-report = "sudo SMART_DRIVES='/dev/nvme0n1:System SSD (ThinkPad)' /home/yanlin/.config/nix/scripts/daily-smart-report.sh AieM4SJHFcyl7TC";
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
    keepassxc
    obsidian
  ];
}
