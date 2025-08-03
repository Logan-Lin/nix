{ pkgs, ... }:

{
  # Font packages
  home.packages = with pkgs; [
    # DejaVu font family
    dejavu_fonts
    
    # Nerd Fonts with programming ligatures and icon support
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;
}