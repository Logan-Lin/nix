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
          acceleration = 0;
          speed = 0.6;
        };
        buttons = {
          mappings = [
            { button = 3; action = "appExpose"; }
            { button = 4; action = "missionControl"; }
            { button = 2; action = "smartZoom"; }
            { scroll = "left"; action = { keyPress = [ "leftArrow" ]; }; }
            { scroll = "right"; action = { keyPress = [ "rightArrow" ]; }; }
          ];
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
