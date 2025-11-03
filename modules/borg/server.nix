{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.borg-server-custom;
in

{
  # options.services.borgbackup-server = {
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
    # Install required packages
    environment.systemPackages = [ pkgs.borgbackup pkgs.openssh ];

    # Create borg-server group
    users.groups.borg-server = {};

    # Create a system user for each borg user
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

    # Ensure proper permissions on data directory
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0755 root borg-server -"
    ] ++ (mapAttrsToList (username: _: 
      "d ${cfg.dataDir}/${username} 0700 ${username} borg-server -"
    ) cfg.users);

    # Configure SSH for borg access
    services.openssh = {
      enable = true;
      ports = [ cfg.sshPort ];
      settings = {
        # Keep connection alive settings
        ClientAliveInterval = 10;
        ClientAliveCountMax = 30;
      };
      extraConfig = ''
        # SSH hardening for borg users
        Match Group borg-server
          PasswordAuthentication no
          PubkeyAuthentication yes
          X11Forwarding no
          AllowAgentForwarding no
          AllowTcpForwarding no
          PermitTunnel no
      '';
    };

    # Open firewall port
    networking.firewall.allowedTCPPorts = mkIf (cfg.sshPort != 22) [ cfg.sshPort ];

    # Create convenience scripts and aliases
    environment.shellAliases = {
      borg-server-status = "systemctl status sshd";
      borg-server-users = "ls -la ${cfg.dataDir}";
      borg-server-logs = "journalctl -u sshd -f";
    };

    # Create a helper script for adding new users
    environment.etc."borg-server/add-user.sh" = {
      text = ''
        set -e
        
        if [ $# -lt 2 ]; then
          echo "Usage: $0 <username> <ssh-public-key>"
          echo "Example: $0 alice 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGxyz...'"
          exit 1
        fi
        
        USERNAME="$1"
        SSH_KEY="$2"
        USER_DIR="${cfg.dataDir}/$USERNAME"
        
        echo "To add user '$USERNAME', add the following to your NixOS configuration:"
        echo ""
        echo "services.borg-server-custom.users.$USERNAME = {"
        echo "  publicKeys = [ \"$SSH_KEY\" ];"
        echo "};"
        echo ""
        echo "Then rebuild your system with: nixos-rebuild switch"
      '';
      mode = "0755";
    };

    # Create a helper script for checking repository info
    environment.etc."borg-server/check-repo.sh" = {
      text = ''
        set -e
        
        if [ $# -lt 1 ]; then
          echo "Usage: $0 <username> [repository]"
          echo "Example: $0 alice"
          echo "Example: $0 alice main-repo"
          exit 1
        fi
        
        USERNAME="$1"
        REPO_NAME="''${2:-}"
        USER_DIR="${cfg.dataDir}/$USERNAME"
        
        if [ ! -d "$USER_DIR" ]; then
          echo "User directory $USER_DIR does not exist"
          exit 1
        fi
        
        if [ -n "$REPO_NAME" ]; then
          REPO_PATH="$USER_DIR/$REPO_NAME"
        else
          echo "Repositories for user $USERNAME:"
          ls -la "$USER_DIR"
          exit 0
        fi
        
        if [ -d "$REPO_PATH" ]; then
          echo "Repository info for $USERNAME/$REPO_NAME:"
          sudo -u "$USERNAME" borg info "$REPO_PATH"
        else
          echo "Repository $REPO_PATH does not exist"
          exit 1
        fi
      '';
      mode = "0755";
    };

  };
}
