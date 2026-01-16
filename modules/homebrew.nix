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
    greedyCasks = true;
    brews = [
      # Command-line tools go here
    ];
    casks = [
      # Development
      "coteditor"
      "ghostty"
      "ovito"
      "balenaetcher"
      "raspberry-pi-imager"
      # Internet & Network
      "clash-verge-rev"
      "firefox"
      "keepassxc"
      "tailscale-app"
      "transmission"
      # Media
      "calibre"
      "handbrake-app"
      "iina"
      "musicbrainz-picard"
      # Productivity
      "affinity"
      "drawio"
      "inkscape"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-word"
      "tencent-meeting"
      "obsidian"
      "omnigraffle"
      "pdf-expert"
      "slidepilot"
      "typora"
      "zotero"
      # Utilities
      "aerospace"
      "hiddenbar"
      "keycastr"
      "localsend"
      "maccy"
      "snipaste"
      "the-unarchiver"
    ];
    taps = [
      "nikitabobko/tap"
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
