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
        hostname = "aicloud";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/.ssh/keys/aicloud";
        proxyJump = "pi";
      };

      "hs" = {
        hostname = "hs.hw.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/nas";
        setEnv = {
          TERM = "xterm-256color";
        };
      };

      "pi" = {
        hostname = "pi.hw.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/pi";
      };

      "personal-vps" = {
        hostname = "personal.vps.yanlincs.com";
        user = "root";
        identityFile = "~/.ssh/keys/hetzner";
      };

      "storage-box" = {
        hostname = "u448310.your-storagebox.de";
        user = "u448310";
        identityFile = "~/.ssh/keys/storage-box";
        port = 23;
      };

    };
  };
}
