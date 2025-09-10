{ config, pkgs, ... }:

{
  # MacBook Air-specific configuration
  networking.computerName = "mba";
  networking.hostName = "mba";
  
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
        "/Users/yanlin/.config/nix/config/wireguard/mba.conf"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      Label = "com.wireguard.mba";
      StandardErrorPath = "/tmp/wireguard.err";
      StandardOutPath = "/tmp/wireguard.out";
    };
  };
}
