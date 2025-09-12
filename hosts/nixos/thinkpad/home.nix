{ config, pkgs, ... }:

{
  # Import the common NixOS home configuration
  imports = [ ../home-default.nix ];

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