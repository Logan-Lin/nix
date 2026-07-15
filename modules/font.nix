# Installs a set of desktop fonts through home-manager and enables fontconfig so applications can use them.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    source-sans-pro
    fira
  ];

  fonts.fontconfig.enable = true;
}
