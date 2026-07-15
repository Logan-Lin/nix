# Podman container runtime for a host that opts into it by importing this module.
# It enables commands compatible with Docker and name resolution between containers on the default network.

{ pkgs, ... }:

{
  config = {
    # IPv4 forwarding lets Podman route traffic between container networks and the outside.
    boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        # netavark is the network backend and aardvark-dns the DNS server that make dns_enabled work.
        extraPackages = [ pkgs.netavark pkgs.aardvark-dns ];
      };
      oci-containers = {
        backend = "podman";
      };
    };
  };
}
