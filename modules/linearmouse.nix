{ config, pkgs, lib, ... }:

{
  # LinearMouse configuration - reversed scrolling and no acceleration for mouse
  home.file.".config/linearmouse/linearmouse.json".text = builtins.toJSON {
    "$schema" = "https://schema.linearmouse.app/0.10.2";
    schemes = [
      {
        "if" = {
          device = {
            category = "mouse";
          };
        };
        scrolling = {
          reverse = {
            vertical = true;
          };
        };
        pointer = {
          disableAcceleration = true;
        };
      }
    ];
  };

  # Auto-start LinearMouse on login
  launchd.agents.linearmouse = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}
