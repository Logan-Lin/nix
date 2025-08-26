{ config, pkgs, lib, ... }:

{
  # Enable Tailscale service
  services.tailscale = {
    enable = true;
    # Override local DNS to use Tailscale's MagicDNS
    # This ensures Tailscale DNS resolution works properly on macOS
    overrideLocalDns = false;
  };

