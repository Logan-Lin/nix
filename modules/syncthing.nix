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
        "ipad" = {
          id = "HPZUOHZ-VMKK246-RBIEHD6-SFTA5DD-2U5LFMX-LXQBGTI-N4C6Z5F-ZVIR6A4";
        };
        "mba" = {
          id = "MRLK24K-BIZSXHQ-TORQTV3-RN6ZBTL-Q5CVXWJ-U3ZJM2J-XGEAQBQ-JFPFUQE";
        };
        "iphone" = {
          id = "NMWI5MP-J4FC4A6-SDDXZPD-G66TJCO-2W7KGFD-RJWQ53U-I7GUVWP-WHF4QQO";
        };
        "imac" = {
          id = "5FVPJMW-ZK2NSM7-H747PTY-XWOJPHC-MBJZWJW-WKAB5BE-KSMQAXQ-QQP6JAG";
        };
        "hs" = {
          id = "GH5D3DJ-PAGKBL6-3VDZJRT-QG4ZMRD-GHCCA3Y-HM2H5CE-NAMJYRR-VHLOOQH";
        };
      };
      
      # Define shared folders
      folders = {
        "Credentials" = {
          path = "~/Credentials";
          devices = [ "ipad" "mba" "iphone" "imac" "hs" ];
          ignorePerms = true;
        };
        "Documents" = {
          path = "~/Documents";
          devices = [ "mba" "imac" "hs" ];
          ignorePerms = true;
        };
        "Obsidian" = {
          path = "~/Obsidian";
          devices = [ "ipad" "mba" "iphone" "imac" "hs" ];
          ignorePerms = true;
        };
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
}
