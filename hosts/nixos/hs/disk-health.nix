{ config, lib, pkgs, ... }:

{
  # Simplified disk health monitoring configuration
  # Focus on smartd real-time monitoring + simple daily SMART reports

  # Package requirements
  environment.systemPackages = with pkgs; [
    smartmontools
    curl         # For Gotify notifications
  ];

  # Enhanced smartd configuration for real-time monitoring
  services.smartd = {
    enable = true;
    autodetect = false;  # We'll configure devices explicitly
    
    # Global smartd options
    extraOptions = [ "-A /var/log/smartd/" "-i 600" ];
    
    # Disable default notifications
    notifications = {
      mail.enable = false;
      x11.enable = false;
      test = false;
    };
    
    # Device-specific monitoring configurations
    devices = [
      # ZFS Mirror drives (NVMe SSDs) - more frequent monitoring
      {
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R";
        options = "-d auto -a -o on -S on -s (S/../.././02|L/../../6/03) -M exec ${pkgs.writeShellScript "smartd-notify-hs-zfs1" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh Ac9qKFH5cA.7Yly ZFS_Mirror_1
        ''}";
      }
      {
        device = "/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG";
        options = "-d auto -a -o on -S on -s (S/../.././02|L/../../6/03) -M exec ${pkgs.writeShellScript "smartd-notify-hs-zfs2" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh Ac9qKFH5cA.7Yly ZFS_Mirror_2
        ''}";
      }
      
      # Data drives (12TB HDDs) - standard monitoring
      {
        device = "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB";
        options = "-d auto -a -o on -S on -s (S/../.././02|L/../../7/03) -W 4,45,55 -M exec ${pkgs.writeShellScript "smartd-notify-hs-data1" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh Ac9qKFH5cA.7Yly Data_Drive_1_12TB
        ''}";
      }
      {
        device = "/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE";
        options = "-d auto -a -o on -S on -s (S/../.././02|L/../../7/03) -W 4,45,55 -M exec ${pkgs.writeShellScript "smartd-notify-hs-data2" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh Ac9qKFH5cA.7Yly Data_Drive_2_12TB
        ''}";
      }
      
      # Parity drive (16TB HDD) - enhanced monitoring due to criticality
      {
        device = "/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE";
        options = "-d auto -a -o on -S on -s (S/../.././02|L/../../1/03) -W 2,45,55 -M exec ${pkgs.writeShellScript "smartd-notify-hs-parity" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh Ac9qKFH5cA.7Yly Parity_Drive_16TB
        ''}";
      }
    ];
  };

  # Simple systemd service for daily SMART reports
  systemd.services = {
    # Daily SMART report service - simplified and reliable
    daily-smart-report = {
      description = "Daily SMART Health Report";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash /home/yanlin/.config/nix/scripts/daily-smart-report.sh Ac9qKFH5cA.7Yly";
        User = "root";
        StandardOutput = "journal";
        StandardError = "journal";
        # Add timeout to prevent hanging
        TimeoutStartSec = "300";  # 5 minutes max
        # Set PATH and SMART_DRIVES environment variables
        Environment = [
          "PATH=/run/current-system/sw/bin"
          "SMART_DRIVES=/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431J4R:ZFS Mirror 1;/dev/disk/by-id/ata-ZHITAI_SC001_XT_1000GB_ZTB401TAB244431KEG:ZFS Mirror 2;/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PK2N4GB:Data Drive 1 (12TB);/dev/disk/by-id/ata-HGST_HUH721212ALE604_5PJ7Z3LE:Data Drive 2 (12TB);/dev/disk/by-id/ata-ST16000NM000J-2TW103_WRS0F8BE:Parity Drive (16TB)"
        ];
        # Allow access to block devices for SMART commands
        DeviceAllow = [ "/dev/disk/by-id/* rw" "/dev/sd* rw" "/dev/nvme* rw" "char-* rw" "block-* rw" ];
        DevicePolicy = "closed";
      };
    };
  };

  # Simple systemd timer for daily SMART reports
  systemd.timers = {
    # Daily SMART report at 8:00 AM
    daily-smart-report = {
      description = "Daily SMART Report Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "08:00:00";
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };

  # Ensure log directories exist with proper permissions
  systemd.tmpfiles.rules = [
    "d /var/log 0755 root root -"
    "f /var/log/daily-smart-report.log 0644 root root -"
    "f /var/log/smartd-alerts.log 0644 root root -"
    "d /var/log/smartd 0755 root root -"
  ];

  # Enable the timer
  systemd.targets.timers.wants = [
    "daily-smart-report.timer"
  ];

  # Create a logrotate configuration for the logs
  services.logrotate = {
    enable = true;
    settings = {
      "/var/log/daily-smart-report.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        create = "644 root root";
      };
      "/var/log/smartd-alerts.log" = {
        frequency = "weekly";
        rotate = 4;
        compress = true;
        delaycompress = true;
        missingok = true;
        notifempty = true;
        create = "644 root root";
      };
    };
  };

  # Ensure scripts are executable and in the right location
  system.activationScripts.disk-health-scripts = ''
    chmod +x /home/yanlin/.config/nix/scripts/gotify-notify.sh
    chmod +x /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh
    chmod +x /home/yanlin/.config/nix/scripts/daily-smart-report.sh
  '';
}