{ pkgs, ... }:

{
  # Font packages
  home.packages = with pkgs; [
    # DejaVu font family
    dejavu_fonts
    
    # Nerd Fonts with programming ligatures and icon support
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    
    # CJK fonts for proper Chinese/Japanese/Korean character display
    noto-fonts-cjk-sans     # Comprehensive CJK support
    noto-fonts-cjk-serif    # Serif CJK text support
    source-han-sans         # High-quality CJK font alternative
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;
}