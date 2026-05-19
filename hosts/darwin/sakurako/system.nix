{ config, pkgs, ... }:

{
  networking.computerName = "sakurako";
  networking.hostName = "sakurako";

  imports = [
    ../system-default.nix
    ../../../modules/vpn/darwin-client.nix
  ];

  services.wireguard-client = {
    enable = true;
    address = "10.2.2.30/24";
    serverPublicKey = "46QHjSzAas5g9Hll1SCEu9tbR5owCxXAy6wGOUoPwUM=";
    serverEndpoint = "91.98.84.215:51820";
  };
}
