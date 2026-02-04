{ config, pkgs, nix-homebrew, ... }:

{
  imports = [
    ../../modules/homebrew.nix
    ../../modules/peripheral/system.nix
    nix-homebrew.darwinModules.nix-homebrew
  ];

  # Nix configuration
  nix.settings.experimental-features = "nix-command flakes";
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
    "https://devenv.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
  ];

  # System configuration
  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  programs.zsh.enable = true;

  # Set primary user for system preferences
  system.primaryUser = "yanlin";

  # Security configuration - passwordless sudo for yanlin
  security.sudo.extraConfig = ''
    yanlin ALL=(ALL) NOPASSWD: ALL
  '';

  system.defaults = {
    dock = {
      autohide = true;                     # Automatically hide and show the dock
      autohide-delay = 0.2;                # Delay before showing the dock (in seconds)
      autohide-time-modifier = 0.5;        # Animation duration for dock show/hide
      orientation = "bottom";               # Dock position: "bottom", "left", or "right"
      tilesize = 48;                       # Size of dock icons (16-128)
      magnification = false;               # Enable magnification when hovering
      minimize-to-application = false;     # Minimize windows to application icon
      show-recents = true;                 # Show recent applications in dock
      show-process-indicators = true;      # Show dots under running apps
      static-only = false;                 # Show only open applications
      mru-spaces = false;                   # Automatically rearrange spaces based on use
      expose-animation-duration = 0.5;     # Mission Control animation speed
      dashboard-in-overlay = false;          # Show Dashboard as overlay
      persistent-apps = [
        "/Applications/Ghostty.app"
        "/Applications/Firefox.app"
        "/Applications/Obsidian.app"
        "/Applications/KeePassXC.app"
      ];
      persistent-others = [
        "/Users/yanlin/Downloads"
      ];  # List of folders/files to keep in dock

      # Hot Corners - Actions:
      # 1 = Disabled, 2 = Mission Control, 3 = Application Windows,
      # 4 = Desktop, 5 = Start Screen Saver, 6 = Disable Screen Saver,
      # 7 = Dashboard, 10 = Put Display to Sleep, 11 = Launchpad,
      # 12 = Notification Center, 13 = Lock Screen, 14 = Quick Note
      wvous-tl-corner = 1;                 # Top left corner action
      wvous-tr-corner = 1;                 # Top right corner action
      wvous-bl-corner = 1;                 # Bottom left corner action
      wvous-br-corner = 1;                 # Bottom right corner action
    };

    finder = {
      AppleShowAllExtensions = true;       # Show all file extensions
      AppleShowAllFiles = false;           # Show hidden files
      CreateDesktop = false;                # Show icons on desktop
      FXEnableExtensionChangeWarning = false; # Warn when changing file extension
      FXPreferredViewStyle = "Nlsv";       # Default view: "icnv"=Icon, "Nlsv"=List, "clmv"=Column, "glyv"=Gallery
      QuitMenuItem = false;                # Allow quitting Finder with ⌘Q
      ShowPathbar = true;                  # Show path bar at bottom
      ShowStatusBar = false;                # Show status bar at bottom
      _FXShowPosixPathInTitle = false;     # Show full POSIX path in title
      _FXSortFoldersFirst = true;          # Sort folders before files
    };

    # --------------------------------------------------------------------------
    # Global Domain Settings (NSGlobalDomain)
    # --------------------------------------------------------------------------
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";        # Dark mode: "Dark" or remove for light
      AppleInterfaceStyleSwitchesAutomatically = false; # Auto switch dark/light
      NSAutomaticWindowAnimationsEnabled = true; # Window animations
      NSDocumentSaveNewDocumentsToCloud = false; # Save to iCloud by default
      NSNavPanelExpandedStateForSaveMode = true; # Expand save panel by default
      PMPrintingExpandedStateForPrint = true; # Expand print panel by default
      NSTableViewDefaultSizeMode = 2;      # Sidebar icon size: 1=small, 2=medium, 3=large
      AppleShowScrollBars = "WhenScrolling";   # "WhenScrolling", "Automatic", or "Always"
      NSScrollAnimationEnabled = true;     # Smooth scrolling
      NSWindowResizeTime = 0.2;            # Window resize animation duration
      _HIHideMenuBar = false;              # Auto-hide menu bar

      NSAutomaticCapitalizationEnabled = false; # Disable automatic capitalization
      NSAutomaticDashSubstitutionEnabled = false; # Disable smart dashes
      NSAutomaticPeriodSubstitutionEnabled = false; # Disable automatic period with double-space
      NSAutomaticQuoteSubstitutionEnabled = false; # Disable smart quotes
      NSAutomaticSpellingCorrectionEnabled = false; # Disable auto-correction
      NSAutomaticInlinePredictionEnabled = false; # Disable inline predictive text
      "com.apple.keyboard.fnState" = false; # Use F1, F2, etc. as standard function keys
    };

    screencapture = {
      disable-shadow = false;               # Disable shadow in screenshots
      location = "~/Downloads";              # Default save location
      type = "png";                        # Screenshot format: png, jpg, pdf, etc.
      show-thumbnail = true;               # Show thumbnail after taking screenshot
    };

    loginwindow = {
      GuestEnabled = false;                # Disable guest account
      ShutDownDisabled = false;            # Allow shutdown from login window
      RestartDisabled = false;             # Allow restart from login window
      SleepDisabled = false;               # Allow sleep from login window
    };

    spaces = {
      spans-displays = false;              # Each display has separate spaces
    };
  };

  system.activationScripts.extraActivation.text = ''
    sudo -u yanlin defaults -currentHost write -globalDomain NSStatusItemSpacing -int 10
    sudo -u yanlin defaults write -globalDomain NSUserKeyEquivalents -dict-add Minimize '\0'

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
