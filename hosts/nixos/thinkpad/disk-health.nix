{ config, lib, pkgs, ... }:

{
  # Simplified disk health monitoring for ThinkPad laptop
  # Single NVMe SSD monitoring with laptop-friendly settings

  # Package requirements
  environment.systemPackages = with pkgs; [
    smartmontools
    curl         # For Gotify notifications
  ];

  # Smartd configuration for laptop NVMe SSD  
  services.smartd = {
    enable = true;
    autodetect = false;  # Explicit configuration
    
    # Global smartd options
    extraOptions = [ "-A /var/log/smartd/" "-i 900" ];  # Check every 15 minutes
    
    # Disable default notifications
    notifications = {
      mail.enable = false;
      x11.enable = false;
      test = false;
    };
    
    # Single NVMe drive monitoring with all options inline
    devices = [
      {
        device = "/dev/nvme0n1";
        options = "-d nvme -a -o on -S on -s (S/../.././03|L/../../7/04) -W 4,60,70 -M exec ${pkgs.writeShellScript "smartd-notify-thinkpad" ''
          export SMARTD_DEVICE="$SMARTD_DEVICE"
          export SMARTD_FAILTYPE="$SMARTD_FAILTYPE"
          export SMARTD_MESSAGE="$SMARTD_MESSAGE"
          /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh AieM4SJHFcyl7TC System_SSD_ThinkPad
        ''}";
      }
    ];
  };

  # Daily SMART report service
  systemd.services = {
    daily-smart-report = {
      description = "Daily SMART Health Report for ThinkPad";
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash /home/yanlin/.config/nix/scripts/daily-smart-report.sh AieM4SJHFcyl7TC";
        User = "root";
        StandardOutput = "journal";
        StandardError = "journal";
        TimeoutStartSec = "300";  # 5 minutes max
        # Environment with single NVMe drive
        Environment = [
          "PATH=/run/current-system/sw/bin"
          "SMART_DRIVES=/dev/nvme0n1:System SSD (ThinkPad)"
        ];
        # Allow access to NVMe devices
        DeviceAllow = [ "/dev/nvme* rw" "char-* rw" "block-* rw" ];
        DevicePolicy = "closed";
      };
    };
  };

  # Daily SMART report timer - runs at 09:00 (later than server)
  systemd.timers = {
    daily-smart-report = {
      description = "Daily SMART Report Timer for ThinkPad";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "09:00:00";  # Later time for laptop
        Persistent = true;
        RandomizedDelaySec = "10m";  # Longer randomization for laptop
      };
    };
  };

  # Ensure log directories exist
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

  # Logrotate configuration
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

  # Ensure scripts are executable
  system.activationScripts.disk-health-scripts = ''
    chmod +x /home/yanlin/.config/nix/scripts/gotify-notify.sh
    chmod +x /home/yanlin/.config/nix/scripts/disk-health-smartd-alert.sh
    chmod +x /home/yanlin/.config/nix/scripts/daily-smart-report.sh
  '';
}