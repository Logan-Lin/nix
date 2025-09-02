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
      "tailscale-app"
      "inkscape"
      "firefox"
      "obsidian"
      "snipaste"
      "ghostty"
      "slidepilot"
      "tencent-meeting"
      "ovito"
      "wechat"
      "microsoft-powerpoint"
      "microsoft-word"
      "microsoft-excel"
      "rectangle"
    ];
    taps = [
      # Additional repositories if needed
    ];
  };

  # nix-homebrew configuration for declarative Homebrew installation
  nix-homebrew = {
    enable = true;
    enableRosetta = true;  # Apple Silicon support
    user = "yanlin";
    autoMigrate = true;    # Migrate existing Homebrew if present
  };
}
