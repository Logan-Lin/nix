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

  config = mkIf cfg.enable {
    services.autofs = {
      enable = true;
      timeout = 300;
      autoMaster =
        let
          # Build server list: primary host followed by replicas
          allHosts = [ cfg.remoteHost ] ++ cfg.replicas;
          # Format as "host1:/path host2:/path host3:/path"
          locations = concatStringsSep " " (map (host: "${host}:${cfg.remotePath}") allHosts);
        in
        ''
          ${cfg.mountPoint} -fstype=nfs4,rw,soft,intr,noatime ${locations}
        '';
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.mountPoint} 0755 root root -"
    ];

    environment.systemPackages = [ pkgs.nfs-utils ];
  };
}
