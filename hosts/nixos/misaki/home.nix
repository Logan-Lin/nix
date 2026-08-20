# Home-manager configuration for misaki, a personal NixOS workstation running the Hyprland Wayland desktop.

{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    texliveFull
    httpie

    obsidian
    keepassxc
    drawio
    inkscape
    localsend
    picard
    clash-verge-rev
    pdfpc
    # Wrap ovito to run natively on Wayland and force Mesa to report OpenGL 3.3, which its renderer needs to start.
    # Build it against ffmpeg 7 because its video encoder does not compile against newer ffmpeg APIs yet.
    (pkgs.symlinkJoin {
      name = "ovito-wrapped";
      paths = [ (pkgs.ovito.override { ffmpeg = pkgs.ffmpeg_7; }) ];
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
    ../../../modules/agent/claude.nix
    ../../../modules/agent/codex.nix
    ../../../modules/agent/opencode.nix
    ../../../modules/ghostty.nix
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
