# NOTE: After install, use the following command to create admin account.
# `sudo -u forgejo forgejo --config /var/lib/forgejo/custom/conf/app.ini admin user create --admin --username <user> --password <pass> --email <email>`

{ config, lib, pkgs, ... }:

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
    environment.systemPackages = [ config.services.forgejo.package ];

    services.forgejo = {
      enable = true;
      lfs.enable = true;
      database.type = "sqlite3";
      settings = {
        DEFAULT.APP_NAME = "Yan Lin's Git Server";
        "ui.meta".DESCRIPTION = "Yan Lin's personal Git server: A small-scale, self-hosted Git server for personal projects and CI/CD workflows.";
        server = {
          DOMAIN = cfg.domain;
          ROOT_URL = "https://${cfg.domain}/";
          HTTP_ADDR = "127.0.0.1";
          HTTP_PORT = cfg.httpPort;
          SSH_PORT = cfg.sshPort;
          LANDING_PAGE = "/yanlin";
        };
        service.DISABLE_REGISTRATION = true;
        actions.ENABLED = true;
        repository.DISABLE_DOWNLOAD_SOURCE_ARCHIVES = true;
      };
    };

  };
}
