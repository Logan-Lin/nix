{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.autofs-custom;
in

{
  options.services.autofs-custom = {
    enable = mkEnableOption "AutoFS automatic mounting";

    remoteHost = mkOption {
      type = types.str;
      description = "Remote NFS server hostname or IP";
    };

    remotePath = mkOption {
      type = types.str;
      description = "Remote path to mount";
    };

    mountPoint = mkOption {
      type = types.str;
      description = "Local mount point";
    };
  };

  config = mkIf cfg.enable {
    services.autofs = {
      enable = true;
      timeout = 300;
      autoMaster = ''
        ${cfg.mountPoint} -fstype=nfs4,rw,soft,intr,noatime ${cfg.remoteHost}:${cfg.remotePath}
      '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 root root -"
    ];

    environment.systemPackages = [ pkgs.nfs-utils ];
  };
}
