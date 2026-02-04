{ config, pkgs, ... }:

{
  home.file.".config/linearmouse/linearmouse.json".text = builtins.toJSON {
    "$schema" = "https://app.linearmouse.org/schema/0.10.0";
    schemes = [{
      "if" = {
        device.category = "mouse";
      };
      scrolling.reverse.vertical = true;
      pointer = {
        acceleration = 0;
        speed = 0.6;
      };
    }];
  };
}
