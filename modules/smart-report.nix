{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.smart-report;
  
  # Create the smart-report script wrapper
  smartReportScript = pkgs.writeShellScriptBin "smart-report" ''
    set -euo pipefail
    
    # Set environment variable if drives are configured
    ${optionalString (cfg.drives != {}) ''
      export SMART_DRIVES="${concatStringsSep ";" (mapAttrsToList (device: name: "${device}:${name}") cfg.drives)}"
    ''}
    
    # Execute the actual script
    exec ${pkgs.bash}/bin/bash ${cfg.scriptPath} ${cfg.gotifyToken}
  '';

in {
  options.services.smart-report = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable SMART disk health reporting";
    };
    
    drives = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Drives to monitor (device path -> name mapping)";
      example = {
        "/dev/disk/by-id/ata-Samsung_SSD" = "System_SSD";
      };
    };
    
    scriptPath = mkOption {
      type = types.str;
      default = "/home/yanlin/.config/nix/scripts/daily-smart-report.sh";
      description = "Path to the SMART report script";
    };
    
    gotifyToken = mkOption {
      type = types.str;
      description = "Gotify notification token";
    };
    
    schedule = mkOption {
      type = types.str;
      default = "08:00:00";
      description = "Time to run the daily report (systemd calendar format)";
    };
    
    enableSystemdService = mkOption {
      type = types.bool;
      default = false;
      description = "Enable systemd timer for automatic daily reports";
    };
  };
  
  config = mkIf cfg.enable {
    # Install the wrapper script package
    environment.systemPackages = [ smartReportScript ];
    
    # Configure systemd service if enabled
    systemd.services.daily-smart-report = mkIf cfg.enableSystemdService {
      description = "Daily SMART Health Report";
      after = [ "multi-user.target" ];
      path = with pkgs; [ smartmontools bash coreutils gnugrep gawk gnused curl ];
      environment = {
        SMART_DRIVES = concatStringsSep ";" (mapAttrsToList (device: name: "${device}:${name}") cfg.drives);
      };
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${smartReportScript}/bin/smart-report";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
    
    systemd.timers.daily-smart-report = mkIf cfg.enableSystemdService {
      description = "Daily SMART Report Timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
    };
  };
}