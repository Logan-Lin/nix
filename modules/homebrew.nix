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
      # Internet & Network
      "clash-verge-rev"
      "firefox"
      "keepassxc"
      "tailscale-app"
      # Media
      "calibre"
      "iina"
      "musicbrainz-picard"
      # Productivity
      "drawio"
      "inkscape"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-word"
      "tencent-meeting"
      "obsidian"
      "slidepilot"
      "zotero"
      # Utilities
      "aerospace"
      "hiddenbar"
      "keycastr"
      "linearmouse"
      "localsend"
      "maccy"
      "snipaste"
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
