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
      # GUI applications go here  
      # Example: "google-chrome"
    ];
    taps = [
      # Additional repositories if needed
    ];
  };
}
