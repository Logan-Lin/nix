{ config, pkgs, ... }:

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

      "hs" = {
        hostname = "10.2.2.20";
        user = "yanlin";
        identityFile = "~/.ssh/keys/nas";
        setEnv = {
          TERM = "xterm-256color";
        };
        proxyJump = "vps";
      };

      "thinkpad" = {
        hostname = "10.2.2.30";
        user = "yanlin";
        identityFile = "~/.ssh/keys/thinkpad";
        setEnv = {
          TERM = "xterm-256color";
        };
        proxyJump = "vps";
      };

      "vps" = {
        hostname = "91.98.84.215";
        user = "yanlin";
        identityFile = "~/.ssh/keys/hetzner";
      };

      "storage-box" = {
        hostname = "u448310.your-storagebox.de";
        user = "u448310";
        identityFile = "~/.ssh/keys/storage-box";
        port = 23;
      };

      "borg-backup" = {
        hostname = "10.2.2.30";
        user = "borg";
        identityFile = "~/.ssh/keys/borg-backup";
        proxyJump = "vps";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

    };
  };
}
