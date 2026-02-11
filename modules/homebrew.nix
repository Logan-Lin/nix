{ config, pkgs, ... }:

{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    greedyCasks = true;
    brews = [
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

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = "yanlin";
    autoMigrate = true;
  };
}
