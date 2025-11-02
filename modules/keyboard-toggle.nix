{ config, pkgs, ... }:

let
  keyboard-toggle = pkgs.writeShellScriptBin "keyboard-toggle" ''
    # Find the AT keyboard event device
    EVENT_DEVICE=$(grep -l "AT Translated Set 2 keyboard" /sys/class/input/event*/device/name | sed 's|/device/name||' | sed 's|.*/||')
    PID_FILE="/tmp/keyboard-grab-$USER.pid"

    if [ -z "$EVENT_DEVICE" ]; then
      echo "✗ Could not find AT keyboard device"
      exit 1
    fi

    # Check if grabber is running
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      # Keyboard is disabled, enable it
      sudo kill $(cat "$PID_FILE")
      rm -f "$PID_FILE"
      echo "✓ Built-in keyboard enabled"
    else
      # Keyboard is enabled, disable it by grabbing the device
      sudo ${pkgs.evtest}/bin/evtest --grab /dev/input/$EVENT_DEVICE > /dev/null 2>&1 &
      echo $! > "$PID_FILE"
      echo "✓ Built-in keyboard disabled"
    fi
  '';
in
{
  # Add the script and required tools to system packages
  environment.systemPackages = [
    keyboard-toggle
    pkgs.libinput
    pkgs.evtest
  ];

  # Add convenient shell alias
  environment.shellAliases = {
    kbt = "keyboard-toggle";
  };

  # Add sudoers rule for passwordless keyboard toggling
  security.sudo.extraRules = [{
    users = [ "yanlin" ];
    commands = [{
      command = "${pkgs.evtest}/bin/evtest --grab /dev/input/*";
      options = [ "NOPASSWD" ];
    } {
      command = "${pkgs.coreutils}/bin/kill";
      options = [ "NOPASSWD" ];
    }];
  }];
}
