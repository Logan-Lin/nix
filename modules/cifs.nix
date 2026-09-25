# CIFS network mounts, paired with a health check that remounts a share whose server session has died.

# NOTE: Credentials file content: `password=your-password`, with mode 600.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cifs-mount;

  mountModule = {
    options = {
      device = mkOption {
        type = types.str;
        example = "//u664260.your-storagebox.de/backup";
        description = "Remote share to mount.";
      };

      username = mkOption {
        type = types.str;
        example = "u664260";
        description = "User name to authenticate as.";
      };

      credentialsFile = mkOption {
        type = types.str;
        example = "/etc/storage-box-password";
        description = "File holding the password.";
      };

      user = mkOption {
        type = types.str;
        default = "yanlin";
        description = "Local owner of the mounted files.";
      };

      group = mkOption {
        type = types.str;
        default = "users";
        description = "Local group of the mounted files.";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "cache=none" ];
        description = "Extra mount options for this share.";
      };
    };
  };

  mkMount = mount: {
    inherit (mount) device;
    fsType = "cifs";
    options = [
      "username=${mount.username}"
      "credentials=${mount.credentialsFile}"
      "uid=${mount.user}"
      "gid=${mount.group}"
      "seal"
      "soft"  # makes file operations fail instead of hang so that the health check can remount
      "echo_interval=30"  # keeps the session alive over idle periods and makes the client notice a dead connection sooner
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.mount-timeout=30"
    ] ++ mount.extraOptions;
  };
in
{
  options.services.cifs-mount = {
    enable = mkEnableOption "CIFS network mounts";

    mounts = mkOption {
      type = types.attrsOf (types.submodule mountModule);
      default = { };
      description = "Shares to mount, keyed by their absolute mount point.";
    };

    checkInterval = mkOption {
      type = types.str;
      default = "2min";
      description = "Time between health checks, in systemd time span format.";
    };
  };

  config = mkIf cfg.enable {
    fileSystems = mapAttrs (_: mkMount) cfg.mounts;

    systemd.services.cifs-mount-health = mkIf (cfg.mounts != { }) {
      description = "CIFS Mount Health Check";
      path = [ pkgs.coreutils pkgs.util-linux pkgs.systemd ];

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
      };

      script = let
        mountPointsStr = concatStringsSep " " (map (m: "'${m}'") (attrNames cfg.mounts));
      in ''
        for mount in ${mountPointsStr}; do
          if timeout 15 touch "$mount/.mount-health"; then
            continue
          fi

          echo "$mount is unresponsive, remounting"
          umount -f -l "$mount" || true
          systemctl start "$(systemd-escape --path --suffix=mount "$mount")"
        done
      '';
    };

    systemd.timers.cifs-mount-health = mkIf (cfg.mounts != { }) {
      description = "CIFS Mount Health Check Timer";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.checkInterval;
      };
    };
  };
}
