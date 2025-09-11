{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.webdav-server;
in
{
  options.services.webdav-server = {
    enable = mkEnableOption "WebDAV file server using dufs";
    
    port = mkOption {
      type = types.port;
      default = 5009;
      description = "Port to listen on";
    };
    
    address = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Address to bind to";
    };
    
    servePath = mkOption {
      type = types.str;
      description = "Path to serve via WebDAV";
    };
    
    auth = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          username = mkOption {
            type = types.str;
            description = "Username for authentication";
          };
          passwordFile = mkOption {
            type = types.str;
            description = "Path to file containing password";
          };
        };
      });
      default = null;
      description = "Authentication configuration";
    };
    
    readOnly = mkOption {
      type = types.bool;
      default = false;
      description = "Make the WebDAV share read-only";
    };
    
    allowUpload = mkOption {
      type = types.bool;
      default = true;
      description = "Allow file uploads";
    };
    
    allowDelete = mkOption {
      type = types.bool;
      default = true;
      description = "Allow file deletion";
    };
    
    allowSearch = mkOption {
      type = types.bool;
      default = true;
      description = "Enable search functionality";
    };

    allowSymlink = mkOption {
      type = types.bool;
      default = false;
      description = "Allow serving symbolic links";
    };

    hideDotFiles = mkOption {
      type = types.bool;
      default = true;
      description = "Hide dot files from listing";
    };
  };
  
  config = mkIf cfg.enable {
    # Install dufs package
    environment.systemPackages = [ pkgs.dufs ];
    
    # Set password file permissions if auth is enabled
    systemd.tmpfiles.rules = mkIf (cfg.auth != null) [
      "z ${cfg.auth.passwordFile} 0640 yanlin users - -"
    ];
    
    # Create systemd service for dufs
    systemd.services.webdav-server = {
      description = "WebDAV server using dufs";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = let
        permissionArgs = concatStringsSep " " (
          (optional cfg.readOnly "--render-index") ++
          (optional (!cfg.allowUpload) "--no-upload") ++
          (optional (!cfg.allowDelete) "--no-delete") ++
          (optional (!cfg.allowSearch) "--no-search") ++
          (optional cfg.allowSymlink "--allow-symlink") ++
          (optional cfg.hideDotFiles "--hidden '.*, .*/'")
        );
      in {
        Type = "simple";
        ExecStart = let
          startScript = pkgs.writeShellScript "dufs-start" ''
            ${if cfg.auth != null then ''
              if [ ! -f "${cfg.auth.passwordFile}" ]; then
                echo "Error: Password file ${cfg.auth.passwordFile} does not exist"
                exit 1
              fi
              AUTH_PASSWORD=$(cat ${cfg.auth.passwordFile} | tr -d '\n')
              exec ${pkgs.dufs}/bin/dufs \
                --bind ${cfg.address} \
                --port ${toString cfg.port} \
                --auth "${cfg.auth.username}:$AUTH_PASSWORD@/:rw" \
                ${permissionArgs} \
                "${cfg.servePath}"
            '' else ''
              exec ${pkgs.dufs}/bin/dufs \
                --bind ${cfg.address} \
                --port ${toString cfg.port} \
                ${permissionArgs} \
                "${cfg.servePath}"
            ''}
          '';
        in "${startScript}";
        Restart = "always";
        RestartSec = "10";
        User = "yanlin";
        Group = "users";
        UMask = "0022";  # Creates dirs as 755, files as 644
        
        # Security hardening
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = if cfg.readOnly then [] else [ cfg.servePath ];
        ReadOnlyPaths = if cfg.readOnly then [ cfg.servePath ] else [];
        NoNewPrivileges = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];  # Added AF_UNIX and AF_NETLINK for interface enumeration
        RestrictNamespaces = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
      };
    };
    
    # Open firewall port if needed (usually not needed as it goes through Traefik)
    # networking.firewall.allowedTCPPorts = [ cfg.port ];
  };
}