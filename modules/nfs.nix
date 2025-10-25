{ config, lib, ... }:

with lib;

let
  cfg = config.services.nfs-custom;
in

{
  options.services.nfs-custom = {
    enable = mkEnableOption "NFS server";

    exportPath = mkOption {
      type = types.str;
      description = "Path to export via NFS";
    };

    allowedNetworks = mkOption {
      type = types.listOf types.str;
      default = [ "10.2.2.0/24" ];
      description = "Networks allowed to access the export (CIDR)";
    };
  };

  config = mkIf cfg.enable {
    services.nfs.server = {
      enable = true;
      exports = ''
        ${cfg.exportPath} ${concatStringsSep " " (map (net: "${net}(rw,sync,no_subtree_check,no_root_squash,fsid=0)") cfg.allowedNetworks)}
      '';
    };
  };
}
