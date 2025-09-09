{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.samba-custom;
in

{
  options.services.samba-custom = {
    enable = mkEnableOption "Samba file sharing service";

    workgroup = mkOption {
      type = types.str;
      default = "WORKGROUP";
      description = "SMB workgroup name";
    };

    serverString = mkOption {
      type = types.str;
      default = "NixOS Samba Server";
      description = "Server description string";
    };

    shares = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          path = mkOption {
            type = types.str;
            description = "Path to the shared directory";
          };
          
          comment = mkOption {
            type = types.str;
            default = "";
            description = "Share description comment";
          };
          
          browseable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether share is browseable";
          };
          
          readOnly = mkOption {
            type = types.bool;
            default = false;
            description = "Whether share is read-only";
          };
          
          guestOk = mkOption {
            type = types.bool;
            default = false;
            description = "Allow guest access";
          };
          
          createMask = mkOption {
            type = types.str;
            default = "0644";
            description = "File creation mask";
          };
          
          directoryMask = mkOption {
            type = types.str;
            default = "0755";
            description = "Directory creation mask";
          };
          
          forceUser = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Force files to be owned by this user";
          };
          
          forceGroup = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Force files to be owned by this group";
          };
          
          validUsers = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of valid users for this share";
          };
        };
      });
      default = {};
      description = "Samba share definitions";
    };

    enableWSDD = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Web Service Discovery (WSD) for SMB discovery";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Open firewall ports for Samba";
    };
  };

  config = mkIf cfg.enable {
    # Enable Samba service
    services.samba = {
      enable = true;
      
      # Enable SMB protocol versions
      package = pkgs.samba4Full;
      
      # Modern Samba configuration using settings
      settings = {
        global = {
          # Server identification
          workgroup = cfg.workgroup;
          "server string" = cfg.serverString;
          
          # Security settings
          security = "user";
          "map to guest" = "never";
          
          # Performance optimizations
          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=524288 SO_SNDBUF=524288";
          deadtime = "30";
          "use sendfile" = "yes";
          
          # Logging
          "log file" = "/var/log/samba/log.%m";
          "max log size" = "1000";
          "log level" = "0";
          
          # Disable printer sharing
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        };
        
        # Generate share configurations
      } // (mapAttrs (name: share: {
        path = share.path;
        browseable = if share.browseable then "yes" else "no";
        "read only" = if share.readOnly then "yes" else "no";
        "guest ok" = if share.guestOk then "yes" else "no";
        "create mask" = share.createMask;
        "directory mask" = share.directoryMask;
        "valid users" = concatStringsSep " " share.validUsers;
        comment = share.comment;
      } // (optionalAttrs (share.forceUser != null) {
        "force user" = share.forceUser;
      }) // (optionalAttrs (share.forceGroup != null) {
        "force group" = share.forceGroup;
      })) cfg.shares);
    };
    
    # Enable SMB discovery
    services.samba-wsdd = mkIf cfg.enableWSDD {
      enable = true;
      openFirewall = cfg.openFirewall;
    };
  };
}
