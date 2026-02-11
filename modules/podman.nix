{ pkgs, ... }:

{
  config = {
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
