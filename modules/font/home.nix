{ pkgs, ... }:

let
  customFonts = pkgs.stdenvNoCC.mkDerivation {
    name = "custom-fonts";
    src = ./fonts;
    installPhase = ''
      mkdir -p $out/share/fonts
      find $src -type f \( -iname "*.ttf" -o -iname "*.otf" -o -iname "*.ttc" -o -iname "*.woff" -o -iname "*.woff2" \) -exec cp {} $out/share/fonts/ \;
    '';
  };
in
{
  home.packages = with pkgs; [
    dejavu_fonts
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    ubuntu-classic
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-sans-pro
    fira
    source-han-sans
    arphic-ukai
    arphic-uming
    wqy_zenhei
    ipafont
    mplus-outline-fonts.githubRelease
    kochi-substitute
    customFonts
  ];

  fonts.fontconfig.enable = true;
}
