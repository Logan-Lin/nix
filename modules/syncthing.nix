{ config, pkgs, lib, ... }:

{
  # Enable Syncthing service
  services.syncthing = {
    enable = true;
    # Don't enable tray on macOS as it requires additional setup
    tray.enable = false;
  };
}