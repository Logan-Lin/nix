{ config, pkgs, lib, ... }:

let
  # Universal container configuration
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for nfss host
  virtualisation.oci-containers.containers = {

    mongodb = {
      image = "docker.io/mongo:7";
      volumes = [ "/var/lib/mongodb:/data/db" ];
      environment = { TZ = systemTZ; };
      environmentFiles = [ "/etc/mongodb-env" ];
      ports = [ "27017:27017" ];
      extraOptions = [ "--network=podman" ];
      autoStart = true;
    };

  };
}
