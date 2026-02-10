{ config, pkgs, lib, ... }:

let
  # Universal container configuration
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for vps host
  virtualisation.oci-containers.containers = {

    # OC Backend Scheduler
    oc-scheduler = {
      image = "localhost/oc-scheduler:v1";

      extraOptions = [
        "--network=podman"
        "--security-opt=no-new-privileges:true"
      ];
      
      autoStart = true;
    };

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
