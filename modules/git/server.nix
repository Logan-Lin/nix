{ config, lib, ... }:

let
  cfg = config.services.git-server-custom;
in
{
  options.services.git-server-custom = {
    enable = lib.mkEnableOption "Forgejo git server";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "localhost";
    };

    httpPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    sshPort = lib.mkOption {
      type = lib.types.port;
      default = 22;
    };
  };

  config = lib.mkIf cfg.enable {
    services.forgejo = {
      enable = true;
      lfs.enable = true;
      database.type = "sqlite3";
      settings = {
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = cfg.httpPort;
          SSH_PORT = cfg.sshPort;
        };
        service.DISABLE_REGISTRATION = true;
      };
    };
  };
}
