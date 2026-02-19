# NOTE: To register a runner instance, create token file at `/var/lib/gitea-runner/<name>/token` with `TOKEN=<token>`

{ config, lib, pkgs, ... }:

let
  cfg = config.services.git-runner-custom;
in
{
  options.services.git-runner-custom = {
    enable = lib.mkEnableOption "Forgejo actions runner";

    url = lib.mkOption {
      type = lib.types.str;
    };

    instances = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.labels = lib.mkOption {
          type = lib.types.listOf lib.types.str;
        };
      });
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    services.gitea-actions-runner.instances = lib.mapAttrs (name: inst: {
      enable = true;
      inherit name;
      inherit (inst) labels;
      url = cfg.url;
      tokenFile = "/var/lib/gitea-runner/${name}/token";
    }) cfg.instances;
  };
}
