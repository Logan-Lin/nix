{ config, pkgs, lib, ... }:

let
  # Common ignore patterns for all synced folders
  commonIgnores = [
    ".DS_Store"
    "*.tmp"
    "*.temp"
    "~*"
    ".*.swp"
    ".*.swo"
    "*~"
    ".Trash-*"
    "Thumbs.db"
    "desktop.ini"
  ];

  # Convert ignore list to .stignore file content
  stignoreContent = lib.concatStringsSep "\n" commonIgnores;

  # Common versioning configuration
  commonVersioning = {
    type = "staggered";
    params = {
      maxAge = "15552000"; # 180 days in seconds
      cleanInterval = "3600"; # Clean every hour
    };
  };
in
{
  # Enable Syncthing service
  services.syncthing = {
    enable = true;
    # Don't enable tray on server (Linux) or macOS
    tray.enable = false;
    
    # Listen on all interfaces for the GUI
    guiAddress = "0.0.0.0:8384";
    
    # Declarative configuration - will override any GUI changes
    overrideDevices = true;
    overrideFolders = true;
    
    settings = {
      # Define all devices
      devices = {
        "iphone" = {
          id = "NMWI5MP-J4FC4A6-SDDXZPD-G66TJCO-2W7KGFD-RJWQ53U-I7GUVWP-WHF4QQO";
        };
        "hs" = {
          id = "GH5D3DJ-PAGKBL6-3VDZJRT-QG4ZMRD-GHCCA3Y-HM2H5CE-NAMJYRR-VHLOOQH";
        };
        "thinkpad" = {
          id = "OMZKASU-QPZDCQ2-7QRHRD4-3TPAXLM-AYRMWXB-A6E5OIZ-MGR422V-JYARQA6";
        };
        "deck" = {
          id = "4LYWEFD-25FGQ7W-DQ7UC2R-LTJCTYQ-3UHXJUC-DRY2RIF-UFGNCZQ-LLFVDAX";
        };
      };
      
      # Define shared folders
      folders = {
        "Credentials" = {
          path = "~/Credentials";
          devices = [ "iphone" "hs" "thinkpad" "deck" ];
          ignorePerms = true;
          versioning = commonVersioning;
        };
        "Documents" = {
          path = "~/Documents";
          devices = [ "hs" "thinkpad" ];
          ignorePerms = true;
          versioning = commonVersioning;
        };
        "Obsidian" = {
          path = "~/Obsidian";
          devices = [ "iphone" "hs" "thinkpad" "deck" ];
          ignorePerms = true;
          versioning = commonVersioning;
        };
      };
      
      # GUI settings with authentication
      gui = {
        enabled = true;
        user = "yanlin";
        password = "1Hayashi-2Hiko"; # You should change this password
        useTLS = false; # TLS is handled by Traefik
      };
      
      # Additional settings
      options = {
        urAccepted = -1;  # Disable usage reporting
        relaysEnabled = true;
        localAnnounceEnabled = true;
        globalAnnounceEnabled = true;
      };
    };
  };

  # Deploy .stignore files to synced folders
  home.file."Credentials/.stignore".text = stignoreContent;
  home.file."Documents/.stignore".text = stignoreContent;
  home.file."Obsidian/.stignore".text = stignoreContent;

  # For NixOS systems, we need to add Syncthing as a manual service in Traefik
  # Since Syncthing runs as a systemd service (not container), we'll handle routing via static config
  # or create a container wrapper for it to use with service discovery
}
