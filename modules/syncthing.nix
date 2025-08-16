{ config, pkgs, lib, ... }:

{
  # Enable Syncthing service
  services.syncthing = {
    enable = true;
    # Don't enable tray on macOS as it requires additional setup
    tray.enable = false;
  };
  
  # Copy existing Syncthing configuration to preserve device ID and settings
  home.activation.syncthingConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    # Create syncthing config directory if it doesn't exist
    mkdir -p "$HOME/.config/syncthing"
    
    # Copy configuration from macOS location if not already present
    if [ ! -e "$HOME/.config/syncthing/config.xml" ]; then
      echo "Migrating Syncthing configuration from macOS location..."
      if [ -d "$HOME/Library/Application Support/Syncthing" ]; then
        cp -r "$HOME/Library/Application Support/Syncthing/"* "$HOME/.config/syncthing/"
        echo "Syncthing configuration migrated successfully!"
      else
        echo "Warning: No existing Syncthing configuration found to migrate"
      fi
    else
      echo "Syncthing configuration already exists at ~/.config/syncthing"
    fi
  '';
}