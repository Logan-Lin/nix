# NOTE: Samba user password manually set: `sudo smbpasswd -a ${cfg.user}`

{ config, pkgs, lib, ... }:

let
  cfg = config.services.samba-custom;
in
{
  options.services.samba-custom = {
    sharedPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to the folder to share via Samba. Set to null to disable Samba sharing.";
      example = "/mnt/storage/shared";
    };

    shareName = lib.mkOption {
      type = lib.types.str;
      default = "shared";
      description = "Name of the Samba share as it appears on the network";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "yanlin";
      description = "Unix user that owns the shared directory and will be used for Samba authentication";
    };
  };

  config = lib.mkIf (cfg.sharedPath != null) {
    # Enable Samba service
    services.samba = {
      enable = true;
      openFirewall = true;

      settings = {
        global = {
          "workgroup" = "WORKGROUP";
          "server string" = "${config.networking.hostName} Samba Server";
          "netbios name" = config.networking.hostName;
          "security" = "user";
          "guest account" = "nobody";
          "map to guest" = "bad user";

          # Security enhancements
          "server min protocol" = "SMB3_00";
          "smb encrypt" = "desired";
        };

        "${cfg.shareName}" = {
          "path" = cfg.sharedPath;
          "valid users" = cfg.user;
          "public" = "no";
          "writeable" = "yes";
          "force user" = cfg.user;
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };

    # Create directory and set permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.sharedPath} 0755 ${cfg.user} users - -"
    ];

  };
}
