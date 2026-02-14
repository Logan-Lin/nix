{ config, pkgs, lib, ... }:

let
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for nfss host
  virtualisation.oci-containers.containers = {

  };
}
