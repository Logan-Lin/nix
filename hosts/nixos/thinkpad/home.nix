{ config, pkgs, firefox-addons, plasma-manager, ... }:

{
  # Import the common NixOS home configuration
  imports = [ 
    ../home-default.nix 
    ../../../modules/firefox.nix
    ../../../modules/plasma.nix
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
    # Battery status alias
    battery = "acpi -b";
    
    # NVIDIA offload aliases for running applications on discrete GPU
    nvidia-run = "nvidia-offload";
    
    # Brightness control aliases
    brightness-up = "brightnessctl set +10%";
    brightness-down = "brightnessctl set 10%-";
  };
}