{ config, ... }:

{
  # Traefik dynamic configuration for vps host
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
      };
      services = {
      };
    };
  };
}
