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

      "zero" = {
        hostname = "zero.hw.yanlincs.com";
        user = "yanlin";
        identityFile = "~/.ssh/keys/pi";
      };

      "ucloud-a40" = {
        hostname = "130.225.38.194";
        user = "ucloud";
        identityFile = "~/.ssh/keys/ucloud";
        proxyJump = "imac";
      };

      "ucloud-h100" = {
        hostname = "ssh.cloud.sdu.dk";
        user = "ucloud";
        port = 2281;
        identityFile = "~/.ssh/keys/ucloud";
      };
    };
  };
}