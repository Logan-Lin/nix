{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.containerUpdater;
in
{
  options.services.containerUpdater = {
    enable = mkEnableOption "automatic container updates";

    schedule = mkOption {
      type = types.str;
      default = "*-*-* 03:00:00";
      example = "daily";
      description = ''
        Systemd timer schedule for container updates.
        Can be a systemd time specification or alias like "daily", "weekly".
      '';
    };

    excludeContainers = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "traefik" "wireguard" ];
      description = ''
        List of container names to exclude from automatic updates.
      '';
    };

    enableNotifications = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Gotify notifications for update status";
    };

    gotifyUrl = mkOption {
      type = types.str;
      default = "";
      example = "https://notify.yanlincs.com";
      description = "Gotify server URL for notifications";
    };

    gotifyToken = mkOption {
      type = types.str;
      default = "";
      example = "Ac9qKFH5cA.7Yly";
      description = "Gotify API token for notifications";
    };
  };

  config = mkIf cfg.enable {
    # Ensure the update script exists and is executable
    system.activationScripts.container-updater = ''
      chmod +x /home/yanlin/.config/nix/scripts/container-update.sh
      chmod +x /home/yanlin/.config/nix/scripts/gotify-notify.sh
    '';
    
    # Shell alias for manual execution
    environment.shellAliases = {
      container-update-now = "sudo systemctl start container-updater.service";
    };

    # Systemd service for container updates
    systemd.services.container-updater = {
      description = "Update podman containers to latest images";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      
      environment = {
        GOTIFY_URL = mkIf cfg.enableNotifications cfg.gotifyUrl;
        GOTIFY_TOKEN = mkIf cfg.enableNotifications cfg.gotifyToken;
        EXCLUDE_CONTAINERS = concatStringsSep "," cfg.excludeContainers;
      };

      path = [ pkgs.podman pkgs.curl pkgs.coreutils pkgs.nettools ];
      
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash /home/yanlin/.config/nix/scripts/container-update.sh";
        User = "root";
        StandardOutput = "journal";
        StandardError = "journal";
        
        # Restart policy
        Restart = "on-failure";
        RestartSec = "5min";
        
        # Timeout for the update process (30 minutes should be enough)
        TimeoutStartSec = "30min";
      };
    };

    # Systemd timer for scheduled updates
    systemd.timers.container-updater = {
      description = "Timer for automatic container updates";
      wantedBy = [ "timers.target" ];
      
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5min";
      };
    };
  };
}