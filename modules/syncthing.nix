{ config, pkgs, lib, ... }:

let
  cfg = config.syncthing-custom;

  # Common ignore patterns for all synced folders
  commonIgnores = [
    ".DS_Store"
    "*.tmp"
    "*.temp"
    "~*"
    ".*.swp"
    ".*.swo"
    "*~"
    ".Trash"
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
  options.syncthing-custom = {
    enabledFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "Credentials" "Documents" "Obsidian" ];
      description = "List of Syncthing folders to enable for this host. Available: Credentials, Documents, Obsidian";
    };
  };

  config = {
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
        "ipad" = {
          id = "ZN3W6K7-VTRRRMT-Y35PSVU-EARJ6FP-6JBFIOF-YAFUAUZ-2TSFW3T-5YGDZAO";
        };
        "macbook" = {
          id = "XPAMYJX-D7UZKPI-JBLTAWG-EBPSFYV-NEFV42V-NIUZKQN-KTVTGGP-OOXL5AT";
        };
      };
      
      # Define shared folders (only enabled ones)
      folders =
        (lib.optionalAttrs (lib.elem "Credentials" cfg.enabledFolders) {
          "Credentials" = {
            path = "~/Credentials";
            devices = [ "iphone" "hs" "thinkpad" "ipad" "macbook" ];
            ignorePerms = true;
            versioning = commonVersioning;
          };
        })
        // (lib.optionalAttrs (lib.elem "Documents" cfg.enabledFolders) {
          "Documents" = {
            path = "~/Documents";
            devices = [ "hs" "thinkpad" "macbook" ];
            ignorePerms = true;
            versioning = commonVersioning;
          };
        })
        // (lib.optionalAttrs (lib.elem "Obsidian" cfg.enabledFolders) {
          "Obsidian" = {
            path = "~/Obsidian";
            devices = [ "hs" "thinkpad" "macbook" ];
            ignorePerms = true;
            versioning = commonVersioning;
          };
        });
      
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

  # Deploy .stignore files to synced folders (only for enabled folders)
  home.file = lib.mkMerge [
    (lib.mkIf (lib.elem "Credentials" cfg.enabledFolders) {
      "Credentials/.stignore".text = stignoreContent;
    })
    (lib.mkIf (lib.elem "Documents" cfg.enabledFolders) {
      "Documents/.stignore".text = stignoreContent;
    })
    (lib.mkIf (lib.elem "Obsidian" cfg.enabledFolders) {
      "Obsidian/.stignore".text = stignoreContent;
    })
  ];

  # For NixOS systems, we need to add Syncthing as a manual service in Traefik
  # Since Syncthing runs as a systemd service (not container), we'll handle routing via static config
  # or create a container wrapper for it to use with service discovery
  };
}
