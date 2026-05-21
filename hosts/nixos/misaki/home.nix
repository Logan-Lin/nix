{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
    keepassxc
    localsend
    obsidian
    drawio
    inkscape
    picard
    clash-verge-rev
    pdfpc
    (pkgs.symlinkJoin {
      name = "ovito-wrapped";
      paths = [ pkgs.ovito ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ovito \
          --set QT_QPA_PLATFORM wayland \
          --set MESA_GL_VERSION_OVERRIDE 3.3
      '';
    })
  ];

  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/media-tool.nix
    ../../../modules/terminal/claude.nix
    ../../../modules/terminal/ghostty.nix
    ../../../modules/firefox.nix
    ../../../modules/hyprland/home.nix
  ];

  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;
    fontSize = 11;
  };

  syncthing-custom.folders = {
    Documents = { enable = true; maxAgeDays = 30; };
  };
}
