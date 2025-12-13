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
    ];
    casks = [
      # GUI applications - manually installed apps now managed by Homebrew
      "cursor"
      "keepassxc"
      "keycastr"
      "inkscape"
      "affinity"
      "firefox"
      "obsidian"
      "snipaste"
      "ghostty"
      "slidepilot"
      "tencent-meeting"
      "ovito"
      "microsoft-powerpoint"
      "microsoft-word"
      "microsoft-excel"
      "balenaetcher"
      "rectangle"
      "maccy"
      "iina"
      "hiddenbar"
      "localsend"
      "calibre"
      "linearmouse"
      "omnigraffle"
      "tailscale-app"
      "typora"
      "zotero"
      "raspberry-pi-imager"
      "transmission"
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
