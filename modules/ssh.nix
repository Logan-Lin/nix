{ config, pkgs, lib, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    matchBlocks = {
      
      "*" = {
        addKeysToAgent = "yes";
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/Credentials/ssh_keys/github";
      };

      "aicloud" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/Credentials/ssh_keys/aicloud";
        proxyJump = "thinkpad";
      };

      "aicloud.lan" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/Credentials/ssh_keys/aicloud";
      };

      "hs" = {
        hostname = "lan.hs.yanlincs.com";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/nas";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "thinkpad" = {
        hostname = "vpn.thinkpad.yanlincs.com";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/thinkpad";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "vps" = {
        hostname = "91.98.84.215";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/hetzner";
      };

      "borg-box" = {
        hostname = "u501367.your-storagebox.de";
        user = "u501367";
        port = 23;
        identityFile = "~/Credentials/ssh_keys/hetzner";
      };

      "borg-thinkpad" = {
        hostname = "vpn.thinkpad.yanlincs.com";
        identityFile = "~/Credentials/ssh_keys/thinkpad";
      };

    };
  };
}
