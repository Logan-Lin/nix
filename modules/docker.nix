{ pkgs, inputs, ... }:

let
  stable = import inputs.nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
in

{
  config = {
    virtualisation = {
      docker = {
        enable = true;
        package = stable.docker;
      };
      oci-containers = {
        backend = "docker";
      };
    };

    # The docker group gives root-equivalent access to the daemon socket, so the user can run docker without sudo.
    users.users.yanlin.extraGroups = [ "docker" ];
  };
}
