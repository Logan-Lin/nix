# Home-manager module that runs user defined shell command sequences on a systemd timer schedule.
# A host declares one or more named instances under services.scheduled-commands, each with its commands, an OnCalendar interval, and an optional random delay.

{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.scheduled-commands;

  # Source the user's zshrc first, so the scheduled commands run with the same PATH, aliases, and functions as an interactive shell.
  makeCommandScript = name: instanceCfg: pkgs.writeScriptBin "${name}-run" ''
    #!${pkgs.zsh}/bin/zsh
    source ${config.home.homeDirectory}/.zshrc

    ${concatStringsSep "\n" instanceCfg.commands}
  '';

  enabledInstances = filterAttrs (_: instanceCfg: instanceCfg.enable) cfg;
in

{
  options.services.scheduled-commands = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkEnableOption "this scheduled command instance";

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

        description = mkOption {
          type = types.str;
          default = "Execute scheduled commands";
          example = "Download YouTube videos from subscriptions";
          description = "Description for the systemd service";
        };
      };
    });
    default = {};
    description = "Scheduled command execution services";
  };

  config = mkMerge [
    {
      home.packages = mapAttrsToList (name: instanceCfg:
        makeCommandScript name instanceCfg
      ) enabledInstances;
    }

    {
      systemd.user.services = mapAttrs' (name: instanceCfg:
        nameValuePair name {
          Unit = {
            Description = instanceCfg.description;
            After = [ "network-online.target" ];
          };

          Service = {
            Type = "oneshot";
            ExecStart = "${makeCommandScript name instanceCfg}/bin/${name}-run";
            StandardOutput = "journal";
            StandardError = "journal";
          };

          # The timer is the only thing that should start this service, so force its target list empty to keep it from being enabled on its own.
          Install = {
            WantedBy = mkForce [];
          };
        }
      ) enabledInstances;

      systemd.user.timers = mapAttrs' (name: instanceCfg:
        nameValuePair name {
          Unit = {
            Description = "Timer for ${instanceCfg.description}";
          };

          Timer = {
            OnCalendar = instanceCfg.interval;
            Persistent = true;
            RandomizedDelaySec = instanceCfg.randomDelay;
          };

          Install = {
            WantedBy = [ "timers.target" ];
          };
        }
      ) enabledInstances;
    }
  ];
}
