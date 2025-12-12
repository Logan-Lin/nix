{ config, pkgs, lib, ... }:

let
  cfg = config.services.ntfy-custom;
in
{
  options.services.ntfy-custom = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for ntfy to listen on";
    };

    baseUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://ntfy.yanlincs.com";
      description = "Base URL for ntfy server";
    };
  };

  config = {
    services.ntfy-sh = {
      enable = true;
      settings = {
        listen-http = ":${toString cfg.port}";
        base-url = cfg.baseUrl;

        # iOS push notification support
        upstream-base-url = "https://ntfy.sh";

        # Authentication
        auth-file = "/var/lib/ntfy-sh/user.db";
        auth-default-access = "deny-all";

        # File attachments
        attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      };
    };

    # Ensure required directories exist
    systemd.tmpfiles.rules = [
      "d /var/lib/ntfy-sh 0755 ntfy-sh ntfy-sh -"
      "d /var/lib/ntfy-sh/attachments 0755 ntfy-sh ntfy-sh -"
    ];
  };
}

# NOTE: After deployment, manage users via ntfy CLI:
#   sudo ntfy user add <username>
#   sudo ntfy user change-pass <username>
#   sudo ntfy access <username> <topic> <read-write|read-only|write-only|deny-all>
#   Example: sudo ntfy access alice "*" read-write
