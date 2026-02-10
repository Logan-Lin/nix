{ config, pkgs, lib, ... }:

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

      "borg-box" = {
        hostname = "u518619.your-storagebox.de";
        user = "u518619";
        port = 23;
        identityFile = "~/Credentials/ssh_keys/hetzner";
      };

      "rpi" = {
        hostname = "rpi.yanlincs.com";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/rpi";
      };

      "nfss" = {
        hostname = "nfss.yanlincs.com";
        user = "yanlin";
        identityFile = "~/Credentials/ssh_keys/nas";
      };

    };
  };
}
