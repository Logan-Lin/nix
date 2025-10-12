{ config, pkgs, lib, ... }:

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
        "mba" = {
          id = "3PBRH37-VR635IP-VZPT3OK-LWMVQ3M-RILX347-3PKPXQK-74GQENC-CMY6OAG";
        };
        "iphone" = {
          id = "NMWI5MP-J4FC4A6-SDDXZPD-G66TJCO-2W7KGFD-RJWQ53U-I7GUVWP-WHF4QQO";
        };
        "ipad" = {
          id = "XQJST6X-IRFHPG5-ULZJE2W-G4XSOIP-M5AMFUZ-IWSDCVT-CQ7FSMC-V4MPUQB";
        };
        "hs" = {
          id = "GH5D3DJ-PAGKBL6-3VDZJRT-QG4ZMRD-GHCCA3Y-HM2H5CE-NAMJYRR-VHLOOQH";
        };
        "thinkpad" = {
          id = "OMZKASU-QPZDCQ2-7QRHRD4-3TPAXLM-AYRMWXB-A6E5OIZ-MGR422V-JYARQA6";
        };
      };
      
      # Define shared folders
      folders = {
        "Credentials" = {
          path = "~/Credentials";
          devices = [ "mba" "iphone" "hs" "thinkpad" "ipad" ];
          ignorePerms = true;
          versioning = {
            type = "staggered";
            params = {
              maxAge = "15552000"; # 180 days in seconds
              cleanInterval = "3600"; # Clean every hour
            };
          };
        };
        "Documents" = {
          path = "~/Documents";
          devices = [ "mba" "hs" "thinkpad" ];
          ignorePerms = true;
          versioning = {
            type = "staggered";
            params = {
              maxAge = "15552000"; # 180 days in seconds
              cleanInterval = "3600"; # Clean every hour
            };
          };
        };
        "Obsidian" = {
          path = "~/Obsidian";
          devices = [ "mba" "iphone" "hs" "thinkpad" ];
          ignorePerms = true;
          versioning = {
            type = "staggered";
            params = {
              maxAge = "15552000"; # 180 days in seconds
              cleanInterval = "3600"; # Clean every hour
            };
          };
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
  
  # Override the launchd agent to add RunAtLoad on macOS
  launchd.agents.syncthing = lib.mkIf (pkgs.stdenv.isDarwin && config.services.syncthing.enable) {
    config.RunAtLoad = true;
  };

  # For NixOS systems, we need to add Syncthing as a manual service in Traefik
  # Since Syncthing runs as a systemd service (not container), we'll handle routing via static config
  # or create a container wrapper for it to use with service discovery
}
