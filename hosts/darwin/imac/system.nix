{ config, pkgs, ... }:

{
  # iMac-specific configuration
  networking.computerName = "imac";
  networking.hostName = "imac";
  
  # Import common Darwin configuration
  imports = [
    ../system-default.nix
  ];

  # WireGuard LaunchAgent for auto-start
  launchd.user.agents.wireguard = {
    serviceConfig = {
      ProgramArguments = [
        "/opt/homebrew/bin/wg-quick"
        "up"
        "/Users/yanlin/.config/nix/config/wireguard/imac.conf"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      Label = "com.wireguard.imac";
      StandardErrorPath = "/tmp/wireguard.err";
      StandardOutPath = "/tmp/wireguard.out";
    };
  };
}
