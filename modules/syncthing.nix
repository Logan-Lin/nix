{ config, pkgs, lib, ... }:

{
  # Enable Syncthing service with auto-start on macOS
  services.syncthing = {
    enable = true;
    # Don't enable tray on macOS as it requires additional setup
    tray.enable = false;
  };
  
  # Override the launchd agent to add RunAtLoad on macOS
  launchd.agents.syncthing = lib.mkIf (pkgs.stdenv.isDarwin && config.services.syncthing.enable) {
    config.RunAtLoad = true;
  };
}