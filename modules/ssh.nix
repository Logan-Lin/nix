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
        hostname = "hs.yanlincs.com";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/nas";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "thinkpad" = {
        hostname = "thinkpad.yanlincs.com";
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

      "borg-server" = {
        hostname = "thinkpad.yanlincs.com";
        user = "borg";
        identityFile = "~/Credentials/ssh_keys/thinkpad";
        proxyJump = "vps";
      };

    };
  };
}
