{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.scheduled-commands;

  # Create wrapper script that sources user shell environment
  commandScript = pkgs.writeScriptBin "${cfg.serviceName}-run" ''
    #!${pkgs.zsh}/bin/zsh
    # Source user shell to get environment and functions
    source ${config.home.homeDirectory}/.zshrc

    # Execute commands sequentially
    ${concatStringsSep "\n" cfg.commands}
  '';
in

{
  options.services.scheduled-commands = {
    enable = mkEnableOption "scheduled command execution service";

    commands = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [
        "echo 'Starting backup...'"
        "rsync -av /source /destination"
        "echo 'Backup completed'"
      ];
      description = "List of shell commands to execute sequentially";
    };

    interval = mkOption {
      type = types.str;
      default = "daily";
      example = "*-*-* 08:00:00";
      description = "Systemd timer schedule (OnCalendar format)";
    };

    randomDelay = mkOption {
      type = types.str;
      default = "0";
      example = "1h";
      description = "Random delay before execution (e.g., '30m', '1h')";
    };

    serviceName = mkOption {
      type = types.str;
      default = "scheduled-commands";
      example = "video-downloads";
      description = "Name for the systemd service and timer";
    };

    serviceDescription = mkOption {
      type = types.str;
      default = "Execute scheduled commands";
      example = "Download YouTube videos from subscriptions";
      description = "Description for the systemd service";
    };
  };

  config = mkIf cfg.enable {
    # Install the wrapper script
    home.packages = [ commandScript ];

    systemd.user.services.${cfg.serviceName} = {
      Unit = {
        Description = cfg.serviceDescription;
        After = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${commandScript}/bin/${cfg.serviceName}-run";
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

    systemd.user.timers.${cfg.serviceName} = {
      Unit = {
        Description = "Timer for ${cfg.serviceDescription}";
      };

      Timer = {
        OnCalendar = cfg.interval;
        Persistent = true;
        RandomizedDelaySec = cfg.randomDelay;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
