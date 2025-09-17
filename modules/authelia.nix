{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.authelia-auth;
in
{
  options.services.authelia-auth = {
    enable = mkEnableOption "Authelia authentication server with Traefik integration";
    
    domain = mkOption {
      type = types.str;
      default = "auth.example.com";
      description = "Domain for Authelia web interface";
    };
    
    secretsPath = mkOption {
      type = types.str;
      default = "/var/lib/authelia/secrets";
      description = "Path to store Authelia secrets";
    };
    
    dataPath = mkOption {
      type = types.str;
      default = "/var/lib/authelia";
      description = "Path to store Authelia data (database, etc.)";
    };
    
    logLevel = mkOption {
      type = types.enum [ "debug" "info" "warn" "error" ];
      default = "info";
      description = "Logging level for Authelia";
    };
    
    defaultRedirectionURL = mkOption {
      type = types.str;
      default = "https://www.example.com";
      description = "Default URL to redirect after successful authentication";
    };
    
    sessionDomain = mkOption {
      type = types.str;
      default = "example.com";
      description = "Domain for session cookies";
    };
    
    smtp = mkOption {
      type = types.nullOr (types.submodule {
        options = {
          host = mkOption {
            type = types.str;
            description = "SMTP server host";
          };
          port = mkOption {
            type = types.port;
            default = 587;
            description = "SMTP server port";
          };
          username = mkOption {
            type = types.str;
            description = "SMTP username";
          };
          passwordFile = mkOption {
            type = types.str;
            description = "Path to file containing SMTP password";
          };
          sender = mkOption {
            type = types.str;
            description = "Email sender address";
          };
        };
      });
      default = null;
      description = "SMTP configuration for email notifications";
    };
    
    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          displayname = mkOption {
            type = types.str;
            description = "Display name for the user";
          };
          hashedPassword = mkOption {
            type = types.str;
            description = "Hashed password (use mkpasswd -m sha512 to generate)";
          };
          email = mkOption {
            type = types.str;
            description = "User email address";
          };
          groups = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Groups the user belongs to";
          };
        };
      });
      default = {};
      example = literalExpression ''
        {
          john = {
            displayname = "John Doe";
            hashedPassword = "$6$rounds=50000$...";
            email = "john@example.com";
            groups = [ "admins" "users" ];
          };
        }
      '';
      description = "User database for Authelia";
    };
    
    accessControl = {
      defaultPolicy = mkOption {
        type = types.enum [ "bypass" "one_factor" "two_factor" "deny" ];
        default = "deny";
        description = "Default access control policy";
      };
      
      rules = mkOption {
        type = types.listOf (types.submodule {
          options = {
            domain = mkOption {
              type = types.either types.str (types.listOf types.str);
              description = "Domain(s) this rule applies to";
            };
            policy = mkOption {
              type = types.enum [ "bypass" "one_factor" "two_factor" "deny" ];
              description = "Policy to apply";
            };
            subject = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Subjects (users/groups) this rule applies to";
            };
            resources = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              description = "Resources (paths) this rule applies to";
            };
          };
        });
        default = [];
        example = literalExpression ''
          [
            {
              domain = "public.example.com";
              policy = "bypass";
            }
            {
              domain = "*.example.com";
              policy = "two_factor";
            }
          ]
        '';
        description = "Access control rules";
      };
    };
  };

  config = mkIf cfg.enable {
    # Create necessary directories
    systemd.tmpfiles.rules = [
      "d ${cfg.dataPath} 0750 authelia authelia - -"
      "d ${cfg.secretsPath} 0750 authelia authelia - -"
    ];
    
    # Create user for Authelia
    users.users.authelia = {
      isSystemUser = true;
      group = "authelia";
      home = cfg.dataPath;
      description = "Authelia authentication server user";
    };
    
    users.groups.authelia = {};
    
    # Generate secrets if they don't exist
    systemd.services.authelia-secrets = {
      description = "Generate Authelia secrets";
      wantedBy = [ "authelia-main.service" ];
      before = [ "authelia-main.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "authelia";
        Group = "authelia";
      };
      script = ''
        # Generate JWT secret if it doesn't exist
        if [ ! -f "${cfg.secretsPath}/jwt_secret" ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "${cfg.secretsPath}/jwt_secret"
          chmod 600 "${cfg.secretsPath}/jwt_secret"
        fi
        
        # Generate storage encryption key if it doesn't exist
        if [ ! -f "${cfg.secretsPath}/storage_encryption_key" ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "${cfg.secretsPath}/storage_encryption_key"
          chmod 600 "${cfg.secretsPath}/storage_encryption_key"
        fi
        
        # Generate session secret if it doesn't exist
        if [ ! -f "${cfg.secretsPath}/session_secret" ]; then
          ${pkgs.openssl}/bin/openssl rand -hex 32 > "${cfg.secretsPath}/session_secret"
          chmod 600 "${cfg.secretsPath}/session_secret"
        fi
      '';
    };
    
    # Generate users database file
    systemd.services.authelia-users = {
      description = "Generate Authelia users database";
      wantedBy = [ "authelia-main.service" ];
      before = [ "authelia-main.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "authelia";
        Group = "authelia";
      };
      script = ''
        cat > "${cfg.dataPath}/users.yml" << 'EOF'
        users:
        ${concatStringsSep "\n" (mapAttrsToList (name: user: ''
          ${name}:
            displayname: "${user.displayname}"
            password: "${user.hashedPassword}"
            email: "${user.email}"
            groups:
            ${concatMapStringsSep "\n" (group: "      - ${group}") user.groups}
        '') cfg.users)}
        EOF
        chmod 600 "${cfg.dataPath}/users.yml"
      '';
    };
    
    # Configure Authelia instance
    services.authelia.instances.main = {
      enable = true;
      
      secrets = {
        jwtSecretFile = "${cfg.secretsPath}/jwt_secret";
        storageEncryptionKeyFile = "${cfg.secretsPath}/storage_encryption_key";
      };
      
      settings = {
        theme = "light";
        default_2fa_method = "totp";
        
        log = {
          level = cfg.logLevel;
        };
        
        server = {
          host = "0.0.0.0";
          port = 9091;
        };
        
        session = {
          name = "authelia_session";
          domain = cfg.sessionDomain;
          same_site = "lax";
          secret = { file = "${cfg.secretsPath}/session_secret"; };
          expiration = "1h";
          inactivity = "5m";
        };
        
        regulation = {
          max_retries = 5;
          find_time = "2m";
          ban_time = "5m";
        };
        
        storage = {
          local = {
            path = "${cfg.dataPath}/db.sqlite3";
          };
        };
        
        notifier = if cfg.smtp != null then {
          smtp = {
            host = cfg.smtp.host;
            port = cfg.smtp.port;
            username = cfg.smtp.username;
            password = { file = cfg.smtp.passwordFile; };
            sender = cfg.smtp.sender;
            disable_require_tls = false;
          };
        } else {
          filesystem = {
            filename = "${cfg.dataPath}/notifications.txt";
          };
        };
        
        authentication_backend = {
          file = {
            path = "${cfg.dataPath}/users.yml";
            watch = true;
            password = {
              algorithm = "argon2";
              argon2 = {
                variant = "argon2id";
                iterations = 3;
                memory = 65536;
                parallelism = 4;
                key_length = 32;
                salt_length = 16;
              };
            };
          };
        };
        
        access_control = {
          default_policy = cfg.accessControl.defaultPolicy;
          rules = map (rule: {
            domain = if isList rule.domain then rule.domain else [ rule.domain ];
            policy = rule.policy;
          } // optionalAttrs (rule.subject != null) {
            subject = rule.subject;
          } // optionalAttrs (rule.resources != null) {
            resources = rule.resources;
          }) cfg.accessControl.rules;
        };
        
        default_redirection_url = cfg.defaultRedirectionURL;
      };
    };
    
    # Add Traefik middleware configuration
    services.traefik.dynamicConfigOptions = mkIf (config.services.traefik.enable or false) {
      http.middlewares.authelia = {
        forwardAuth = {
          address = "http://localhost:9091/api/authz/forward-auth";
          trustForwardHeader = true;
          authResponseHeaders = [
            "Remote-User"
            "Remote-Groups"
            "Remote-Name"
            "Remote-Email"
          ];
        };
      };
      
      # Add router for Authelia itself
      http.routers.authelia = {
        rule = "Host(`${cfg.domain}`)";
        entrypoints = [ "websecure" ];
        service = "authelia";
        tls = {
          certResolver = "cloudflare";
          domains = [{
            main = "*.${cfg.sessionDomain}";
          }];
        };
      };
      
      http.services.authelia = {
        loadBalancer = {
          servers = [{
            url = "http://localhost:9091";
          }];
        };
      };
    };
    
    # Ensure Authelia starts after network
    systemd.services.authelia-main = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}