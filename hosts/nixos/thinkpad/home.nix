{ config, pkgs, ... }:

{
  # Allow unfree packages in home-manager
  nixpkgs.config.allowUnfree = true;

  # Import the common NixOS home configuration
  imports = [
    ../home-default.nix
    ../../../modules/syncthing.nix
    ../../../modules/tex.nix
    ../../../modules/gnome/home.nix
    ../../../modules/firefox.nix
    ../../../modules/ghostty.nix
    ../../../modules/papis.nix
    ../../../modules/libreoffice.nix
    ../../../modules/schedule.nix
  ];

  # Enable Ghostty terminal with OSC-52 clipboard support
  programs.ghostty-custom = {
    enable = true;
    package = pkgs.ghostty;
    fontSize = 12;
    windowMode = "maximized";
  };

  # Enable Firefox browser
  programs.firefox-custom = {
    enable = true;
    package = pkgs.firefox;
  };

  # ThinkPad-specific applications
  home.packages = with pkgs; [
    obsidian
    keepassxc
    imagemagick
    inkscape
    vlc
    obs-studio
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
    remmina
    chromium
    localsend
    calibre
  ];
}
