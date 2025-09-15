{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
  ];

  # iMac-specific home configuration
  # Example: Different screen setup, desktop-specific tools, etc.
  
  # yt-dlp configuration
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "~/Downloads/Videos";
  };
}
