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
        identityFile = "~/.ssh/keys/github";
      };

      "aicloud" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/.ssh/keys/aicloud";
        proxyJump = "thinkpad";
      };

      "aicloud.lan" = {
        hostname = "ai-fe02.srv.aau.dk";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/.ssh/keys/aicloud";
      };

      "hs" = {
        hostname = "lan.hs.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/nas";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "thinkpad" = {
        hostname = "vpn.thinkpad.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/thinkpad";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "vps" = {
        hostname = "91.98.84.215";
        user = "yanlin";
        identityFile = "~/.ssh/keys/hetzner";
      };

      "borg-box" = {
        hostname = "u501367.your-storagebox.de";
        user = "u501367";
        port = 23;
        identityFile = "~/.ssh/keys/hetzner";
      };

    };
  };
}
