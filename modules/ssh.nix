{ config, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    
    matchBlocks = {

      "aicloud" = {
        hostname = "aicloud";
        user = "hb05nk@cs.aau.dk";
        identityFile = "~/.ssh/keys/aicloud";
        proxyJump = "pi";
      };

      "nas" = {
        hostname = "nas.hw.yanlincs.com";
        user = "root";
        identityFile = "~/.ssh/keys/nas";
      };

      "pi" = {
        hostname = "pi.hw.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/pi";
      };

      "cm" = {
        hostname = "cm.hw.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/pi";
      };

      "personal-vps" = {
        hostname = "personal.vps.yanlincs.com";
        user = "root";
        identityFile = "~/.ssh/keys/hetzner";
      };

    };
  };
}
