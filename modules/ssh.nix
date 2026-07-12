{ config, pkgs, lib, ... }:

let
  keyDir = "~/.ssh/keys";
in
{
  home.packages = [ pkgs.openssh ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    
    settings = {

      "*" = {
        AddKeysToAgent = "yes";
        IdentitiesOnly = true;
        SendEnv = [ "LANG" "LC_*" ];
      };

      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "${keyDir}/github";
      };

      "aau-gateway" = {
        HostName = "sshgw.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
      };

      "aicloud" = {
        HostName = "ai-fe02.srv.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
        ProxyJump = "misaki";
      };

      "aicloud.lan" = {
        HostName = "ai-fe02.srv.aau.dk";
        User = "hb05nk@cs.aau.dk";
        IdentityFile = "${keyDir}/aicloud";
      };

      "hanako" = {
        HostName = "91.98.84.215";
        User = "yanlin";
        IdentityFile = "${keyDir}/hetzner";
      };

      "oomuroke" = {
        HostName = "u546684.your-storagebox.de";
        User = "u546684";
        Port = 23;
        IdentityFile = "${keyDir}/hetzner";
      };

      "nadeshiko" = {
        HostName = "nadeshiko";
        User = "yanlin";
        IdentityFile = "${keyDir}/nas";
      };

      "misaki" = {
        HostName = "misaki";
        User = "yanlin";
        IdentityFile = "${keyDir}/thinkpad";
      };

      "sakurako" = {
        HostName = "sakurako";
        User = "yanlin";
        IdentityFile = "${keyDir}/mac";
      };

      "himawari" = {
        HostName = "himawari";
        User = "yanlin";
        IdentityFile = "${keyDir}/mac";
      };

    };
  };
}
