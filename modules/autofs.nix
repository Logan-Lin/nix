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
      description = "Primary remote NFS server hostname or IP";
    };

    remotePath = mkOption {
      type = types.str;
      description = "Remote path to mount";
    };

    mountPoint = mkOption {
      type = types.str;
      description = "Local mount point";
    };

    replicas = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Replica server hostnames or IPs for failover (in order of preference)";
    };
  };

  config = mkIf cfg.enable (
    let
      # Build server list: primary host followed by replicas
      allHosts = [ cfg.remoteHost ] ++ cfg.replicas;
      # Format as "host1,host2,host3:/path" for NFS replicas
      locations = "${concatStringsSep "," allHosts}:${cfg.remotePath}";
    in
    {
      services.autofs = {
        enable = true;
        timeout = 300;
        autoMaster = ''
          /-  /etc/auto.nfs --timeout=300
        '';
      };

      # Create the auto.nfs map file
      environment.etc."auto.nfs".text = ''
        ${cfg.mountPoint} -fstype=nfs4,rw,soft,intr,noatime ${locations}
      '';

      systemd.tmpfiles.rules = [
        "d ${cfg.mountPoint} 0755 root root -"
      ];

      environment.systemPackages = [ pkgs.nfs-utils ];
    }
  );
}
