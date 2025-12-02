{ config, pkgs, lib, ... }:

{
  environment.etc."logid.cfg".text = ''
    devices: ({
      name: "MX Master 3 for Mac";

      thumbwheel: {
        invert: true;
        divert: false;
      };

    });
  '';

  systemd.services.logiops = {
    description = "Logitech Configuration Daemon";
    wantedBy = [ "graphical.target" ];
    after = [ "graphical.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.logiops}/bin/logid";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  systemd.services.logiops-resume = {
    description = "Restart logiops after resume";
    after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.systemd.package}/bin/systemctl --no-block restart logiops.service";
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTRS{id/vendor}=="046d", RUN{program}="${config.systemd.package}/bin/systemctl --no-block try-restart logiops.service"
  '';
}
