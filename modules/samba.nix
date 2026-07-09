# NOTE: After deployment, set the password with the command:
#   sudo smbpasswd -a <user>

{ config, lib, ... }:

let
  cfg = config.services.samba-share;

  shareModule = {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        example = "/mnt/storage";
        description = "Absolute path of the directory to export.";
      };

      validUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = cfg.users;
        description = "System users allowed to access the share.";
      };
    };
  };

  mkShare = name: share:
    {
      "path" = share.path;
      "comment" = name;
      "browseable" = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0644";
      "directory mask" = "0755";
    }
    // lib.optionalAttrs (share.validUsers != [ ]) {
      "valid users" = lib.concatStringsSep " " share.validUsers;
    };
in
{
  options.services.samba-share = {
    enable = lib.mkEnableOption "Samba file sharing for a personal homelab";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "yanlin" ];
      description = "Default system users granted access to shares that do not override validUsers.";
    };

    hostsAllow = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "192.168.1." "10.2.2." "127." ];
      description = "If non-empty, restrict access to these hosts or subnet prefixes.";
    };

    shares = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule shareModule);
      default = { };
      description = "Share points exported by the server, keyed by share name.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "%h";
          "server role" = "standalone server";
          "map to guest" = "never";
          "server min protocol" = "SMB2";
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:resource" = "stream";
        }
        // lib.optionalAttrs (cfg.hostsAllow != [ ]) {
          "hosts allow" = lib.concatStringsSep " " cfg.hostsAllow;
        };
      } // lib.mapAttrs mkShare cfg.shares;
    };

    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
      workgroup = "WORKGROUP";
    };
  };
}
