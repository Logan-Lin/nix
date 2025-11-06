{ pkgs, ... }:

let
  # Custom fonts from local files
  customFonts = pkgs.stdenvNoCC.mkDerivation {
    name = "custom-fonts";
    src = ../config/fonts;

    installPhase = ''
      mkdir -p $out/share/fonts
      find $src -type f \( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" -o -name "*.woff" -o -name "*.woff2" \) -exec cp {} $out/share/fonts/ \;
    '';
  };
in
{
  # Font packages
  home.packages = with pkgs; [
    # DejaVu font family
    dejavu_fonts

    # Nerd Fonts with programming ligatures and icon support
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono

    # Ubuntu font family
    ubuntu_font_family

    # CJK fonts for proper Chinese/Japanese/Korean character display
    noto-fonts-cjk-sans     # Comprehensive CJK support
    noto-fonts-cjk-serif    # Serif CJK text support
    source-han-sans         # High-quality CJK font alternative

    # Traditional Chinese font styles
    arphic-ukai             # KaiTi style (楷体) - brush stroke style
    arphic-uming            # MingTi/Song style (宋体) - serif style
    wqy_zenhei              # WenQuanYi Zen Hei - popular sans-serif with good coverage

    # Custom fonts from config/fonts directory
    customFonts
  ];

  # Enable font configuration
  fonts.fontconfig.enable = true;
}
