{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.disable-keyboard;
in

{
  options.services.disable-keyboard = {
    enable = mkEnableOption "automatically disable internal keyboard when specific external keyboard is connected";

    externalKeyboardName = mkOption {
      type = types.str;
      default = "";
      example = "HHKB-Hybrid_1";
      description = ''
        The name of the external keyboard that triggers disabling the internal keyboard.
        This should match the ATTRS{name} value shown in udevadm info or Bluetooth device settings.
        Use `libinput list-devices` or `udevadm monitor` to find the exact name.
      '';
    };

    internalKeyboardName = mkOption {
      type = types.str;
      default = "AT Translated Set 2 keyboard";
      description = ''
        The name of the internal keyboard to disable.
        Default is "AT Translated Set 2 keyboard" which is standard for most laptops.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Install evtest package for grabbing keyboard input
    environment.systemPackages = [ pkgs.evtest ];

    # Systemd service to grab (disable) the internal keyboard
    systemd.services.disable-keyboard = {
      description = "Disable internal keyboard (${cfg.internalKeyboardName}) using evtest";
      serviceConfig = {
        Type = "simple";
        # Wait for device to be ready, then find and grab the internal keyboard
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = pkgs.writeShellScript "disable-keyboard" ''
          # Find the event device for the internal keyboard
          INTERNAL_KB_EVENT=$(${pkgs.gnugrep}/bin/grep -l "${cfg.internalKeyboardName}" /sys/class/input/event*/device/name 2>/dev/null | ${pkgs.gnused}/bin/sed 's|/sys/class/input/\(.*\)/device/name|/dev/input/\1|' | head -n1)

          if [ -z "$INTERNAL_KB_EVENT" ]; then
            echo "Internal keyboard '${cfg.internalKeyboardName}' not found"
            exit 1
          fi

          echo "Disabling internal keyboard: $INTERNAL_KB_EVENT"
          # Use evtest --grab to exclusively grab the device (prevents events from reaching the system)
          exec ${pkgs.evtest}/bin/evtest --grab "$INTERNAL_KB_EVENT" > /dev/null 2>&1
        '';
        Restart = "on-failure";
        RestartSec = "5s";
      };
      wantedBy = [];  # Don't start automatically on boot, only via udev trigger
    };

    # udev rules to detect external keyboard connection/disconnection
    services.udev.extraRules = ''
      # When the specified external keyboard connects, start the disable service
      ACTION=="add", SUBSYSTEM=="input", ENV{ID_INPUT_KEYBOARD}=="1", ATTRS{name}=="${cfg.externalKeyboardName}", TAG+="systemd", ENV{SYSTEMD_WANTS}="disable-keyboard.service"

      # When the external keyboard disconnects, stop the service (re-enable internal keyboard)
      ACTION=="remove", SUBSYSTEM=="input", ENV{ID_INPUT_KEYBOARD}=="1", ATTRS{name}=="${cfg.externalKeyboardName}", RUN+="${pkgs.systemd}/bin/systemctl stop disable-keyboard.service"
    '';
  };
}
