# SSH client configuration for home-manager.
# It defines a global default block and a block for each host.
# A host opts in by importing this module.

{ config, pkgs, lib, ... }:

let
  keyDir = "~/.ssh/keys";
in
{
  home.packages = [ pkgs.openssh ];

  programs.ssh = {
    enable = true;
    # Disable home-manager's default block so the "*" block below is the only global configuration.
    enableDefaultConfig = false;
    
    settings = {

      "*" = {
        AddKeysToAgent = "yes";
        # Offer only the identity file matched for each host instead of every key loaded in the agent.
        IdentitiesOnly = true;
        SendEnv = [ "LANG" "LC_*" ];
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${keyDir}/github";
      };

      "aau-gateway" = {
        HostName = "sshgw.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
      };

      "aicloud" = {
        HostName = "ai-fe02.srv.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
        # Reach this host through the misaki jump host from outside the network.
        # The aicloud.lan entry below is the direct route from inside.
        ProxyJump = "misaki";
      };

      "aicloud.lan" = {
        HostName = "ai-fe02.srv.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
      };

      "hanako" = {
        HostName = "91.98.84.215";
        User = "yanlin";
        IdentityFile = "${keyDir}/hetzner";
      };

      # The Hetzner Storage Box that receives the Borg backups, named 大室家 after the Oomuro family home itself.
      # It holds the backups of every host, the way the family home holds all the sisters.
      "oomuroke" = {
        HostName = "u546684.your-storagebox.de";
        User = "u546684";
        Port = 23;
        IdentityFile = "${keyDir}/hetzner";
      };

      "nadeshiko" = {
        HostName = "nadeshiko";
        User = "yanlin";
        IdentityFile = "${keyDir}/nas";
      };

      "misaki" = {
        HostName = "misaki";
        User = "yanlin";
        IdentityFile = "${keyDir}/thinkpad";
      };

      "sakurako" = {
        HostName = "sakurako";
        User = "yanlin";
        IdentityFile = "${keyDir}/mac";
      };

      "himawari" = {
        HostName = "himawari";
        User = "yanlin";
        IdentityFile = "${keyDir}/mac";
      };

    };
  };
}
