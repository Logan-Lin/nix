# NOTE: Samba user password manually set: `sudo smbpasswd -a ${cfg.user}`

{ config, pkgs, lib, ... }:

let
  cfg = config.services.samba-custom;

  mkShareSettings = _: path: {
    "path" = path;
    "valid users" = cfg.user;
    "public" = "no";
    "writeable" = "yes";
    "force user" = cfg.user;
    "create mask" = "0644";
    "directory mask" = "0755";
  };
in
{
  options.services.samba-custom = {
    shares = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      description = "Samba shares to expose. Keys are share names, values are paths.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "yanlin";
      description = "Unix user that owns the shared directories and will be used for Samba authentication";
    };
  };

  config = lib.mkIf (cfg.shares != {}) {
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
          "server min protocol" = "SMB3_00";
          "smb encrypt" = "desired";
        };
      } // lib.mapAttrs mkShareSettings cfg.shares;
    };

    systemd.tmpfiles.rules = lib.mapAttrsToList
      (_: path: "d ${path} 0755 ${cfg.user} users - -")
      cfg.shares;
  };
}
