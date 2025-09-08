{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service for NixOS
  services.tailscale = {
    enable = true;
    # Enable MagicDNS for better name resolution on NixOS server
    useRoutingFeatures = "server";
  };

  # Allow Tailscale through the firewall if enabled
  networking.firewall = {
    # Allow Tailscale UDP port
    allowedUDPPorts = [ 41641 ];
    # Allow traffic from Tailscale subnet
    trustedInterfaces = [ "tailscale0" ];
  };
}
