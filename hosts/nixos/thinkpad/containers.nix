{ config, pkgs, lib, ... }:

let
  # Import Immich configuration from declarative config file
  immichConfig = import ../../../config/immich.nix;

  # Convert Nix configuration to JSON string
  immichConfigJson = builtins.toJSON immichConfig;

  # Write config file to a location accessible by the container
  immichConfigFile = pkgs.writeText "immich.json" immichConfigJson;

  # Universal container configuration
  commonUID = "1000";
  commonGID = "100";
  systemTZ = config.time.timeZone;
in
{
  # Container definitions for thinkpad host
  virtualisation.oci-containers.containers = {

  };
}
