{ config, pkgs, lib, ... }:

let
  keyDir = "~/.ssh/keys";
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

      "aau-gateway" = {
        hostname = "sshgw.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "${keyDir}/aicloud";
      };

      "aicloud" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "${keyDir}/aicloud";
        proxyJump = "nadeshiko";
      };

      "aicloud.lan" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "${keyDir}/aicloud";
      };

      "hanako" = {
        hostname = "91.98.84.215";
        user = "yanlin";
        identityFile = "${keyDir}/hetzner";
      };

      "helsinki-box" = {
        hostname = "u546684.your-storagebox.de";
        user = "u546684";
        port = 23;
        identityFile = "${keyDir}/hetzner";
      };

      "nadeshiko" = {
        hostname = "10.2.2.10";
        user = "yanlin";
        identityFile = "${keyDir}/nas";
      };

      "misaki" = {
        hostname = "10.2.2.20";
        user = "yanlin";
        identityFile = "${keyDir}/thinkpad";
      };

      "macbook" = {
        hostname = "10.2.2.30";
        user = "yanlin";
        identityFile = "${keyDir}/mac";
      };

      "imac" = {
        hostname = "10.2.2.40";
        user = "yanlin";
        identityFile = "${keyDir}/mac";
      };

    };
  };
}
