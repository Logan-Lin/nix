{ config, pkgs, lib, ... }:

let
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for thinkpad host
  virtualisation.oci-containers.containers = {

  };
}
