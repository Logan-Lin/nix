{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borg-server-custom;
in

{
  options.services.borg-server-custom = {
    enable = mkEnableOption "Borg backup server";

    dataDir = mkOption {
      type = types.str;
      default = "/srv/borg";
      example = "/mnt/backup/borg";
      description = "Base directory for all borg repositories";
    };

    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          publicKeys = mkOption {
            type = types.listOf types.str;
            example = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxyz..." ];
            description = "List of SSH public keys for this user";
          };
        };
      });
      default = {};
      example = {
        alice = {
          publicKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxyz..." ];
        };
      };
      description = "Borg backup users configuration";
    };

    sshPort = mkOption {
      type = types.port;
      default = 22;
      example = 2222;
      description = "SSH port for borg connections";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.borgbackup pkgs.openssh ];

    users.groups.borg-server = {};

    users.users = mapAttrs (username: userCfg: {
      isSystemUser = true;
      group = "borg-server";
      home = "${cfg.dataDir}/${username}";
      createHome = true;
      shell = pkgs.bash;
      description = "Borg backup user ${username}";
      openssh.authorizedKeys.keys = map (key:
        "command=\"borg serve --restrict-to-path ${cfg.dataDir}/${username}\",restrict ${key}"
      ) userCfg.publicKeys;
    }) cfg.users;

    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root borg-server -"
    ] ++ (mapAttrsToList (username: _:
      "d ${cfg.dataDir}/${username} 0700 ${username} borg-server -"
    ) cfg.users);

    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      settings = {
        ClientAliveInterval = 10;
        ClientAliveCountMax = 30;
      };
      extraConfig = ''
        Match Group borg-server
          PasswordAuthentication no
          PubkeyAuthentication yes
          X11Forwarding no
          AllowAgentForwarding no
          AllowTcpForwarding no
          PermitTunnel no
      '';
    };

    networking.firewall.allowedTCPPorts = mkIf (cfg.sshPort != 22) [ cfg.sshPort ];

    environment.shellAliases = {
      borg-server-status = "systemctl status sshd";
      borg-server-users = "ls -la ${cfg.dataDir}";
      borg-server-logs = "journalctl -u sshd -f";
      borg-server-check = "f() { sudo -u \"$1\" borg info \"${cfg.dataDir}/$1/$2\"; }; f";
    };
  };
}
