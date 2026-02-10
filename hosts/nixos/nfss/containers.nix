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

  };
}
