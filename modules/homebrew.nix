{ config, pkgs, ... }:

{
  # Homebrew configuration for package management
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";    # Removes unlisted formulae/casks
      upgrade = true;
    };
    brews = [
      # Command-line tools go here
      # Example: "wget"
    ];
    casks = [
      # GUI applications - manually installed apps now managed by Homebrew
      "inkscape"
      "firefox"
      "obsidian"
      "snipaste"
      "ghostty"
      "slidepilot"
      "tencent-meeting"
      "ovito"
    ];
    taps = [
      # Additional repositories if needed
    ];
  };
}
