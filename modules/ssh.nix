{ config, pkgs, lib, ... }:

let
  keyDir = "~/Credentials/ssh_keys";
in
{
  home.packages = [ pkgs.openssh ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    matchBlocks = {
      
      "*" = {
        addKeysToAgent = "yes";
        identitiesOnly = true;
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "${keyDir}/github";
      };

      "aicloud" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "${keyDir}/aicloud";
        proxyJump = "thinkpad";
      };

      "aicloud.lan" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "${keyDir}/aicloud";
      };

      "thinkpad" = {
        hostname = "10.2.2.20";
        user = "yanlin";
        identityFile = "${keyDir}/thinkpad";
        setEnv = {
          TERM = "xterm-256color";
        };
        proxyJump = "vps";
      };

      "vps" = {
        hostname = "91.98.84.215";
        user = "yanlin";
        identityFile = "${keyDir}/hetzner";
      };

      "git.yanlincs.com" = {
        user = "forgejo";
        identityFile = "${keyDir}/hetzner";
      };

      "borg-box" = {
        hostname = "u518619.your-storagebox.de";
        user = "u518619";
        port = 23;
        identityFile = "${keyDir}/hetzner";
      };

      "helsinki-box" = {
        hostname = "u546684.your-storagebox.de";
        user = "u546684";
        port = 23;
        identityFile = "${keyDir}/hetzner";
      };

      "nfss" = {
        hostname = "10.2.2.10";
        user = "yanlin";
        identityFile = "${keyDir}/nas";
        proxyJump = "vps";
      };

      "nfss.lan" = {
        hostname = "10.1.1.152";
        user = "yanlin";
        identityFile = "${keyDir}/nas";
      };

    };
  };
}
