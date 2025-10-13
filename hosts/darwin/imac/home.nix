{ config, pkgs, ... }:

{
  imports = [
    ../home-default.nix
  ];

  # MacBook Air-specific home configuration
  # Example: Laptop-specific tools, power management, etc.
  
  # yt-dlp configuration
  programs.yt-dlp-custom = {
    enable = true;
    downloadDir = "~/Downloads/Videos";
  };
}
