{ pkgs, ... }:

{
  config = {
    boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        extraPackages = [ pkgs.netavark pkgs.aardvark-dns ];
      };
      oci-containers = {
        backend = "podman";
      };
    };
  };
}
