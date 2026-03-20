{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = "yanlin";
  };

  nix.gc = {
    automatic = true;
    interval = { Day = 1; };
    options = "--delete-older-than 30d";
  };

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

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";
  programs.zsh.enable = true;

  system.primaryUser = "yanlin";

  security.sudo.extraConfig = ''
    yanlin ALL=(ALL) NOPASSWD: ALL
  '';

  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.2;
      autohide-time-modifier = 0.5;
      orientation = "bottom";
      tilesize = 48;
      magnification = false;
      minimize-to-application = false;
      show-recents = false;
      show-process-indicators = true;
      static-only = false;
      mru-spaces = false;
      expose-animation-duration = 0.5;
      dashboard-in-overlay = false;
      persistent-apps = [
      ];
      persistent-others = [
        "/Users/yanlin/Downloads"
      ];

      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      CreateDesktop = false;
      FXEnableExtensionChangeWarning = false;
      QuitMenuItem = false;
      ShowPathbar = true;
      ShowStatusBar = false;
      _FXShowPosixPathInTitle = false;
    };

    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleInterfaceStyleSwitchesAutomatically = false;
      NSAutomaticWindowAnimationsEnabled = true;
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      PMPrintingExpandedStateForPrint = true;
      NSTableViewDefaultSizeMode = 2;
      AppleShowScrollBars = "Always";
      NSScrollAnimationEnabled = true;
      NSWindowResizeTime = 0.2;
      _HIHideMenuBar = false;

      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticInlinePredictionEnabled = false;
      "com.apple.keyboard.fnState" = false;
      AppleScrollerPagingBehavior = true;
    };

    CustomUserPreferences = {
      NSGlobalDomain.NSGlassDiffusionSetting = 1;
    };

    screencapture = {
      disable-shadow = true;
      location = "~/Downloads";
      type = "png";
      show-thumbnail = true;
    };

    loginwindow = {
      GuestEnabled = false;
      ShutDownDisabled = false;
      RestartDisabled = false;
      SleepDisabled = false;
    };

    spaces = {
      spans-displays = false;
    };

};

  system.activationScripts.extraActivation.text = ''
    sudo -u yanlin defaults -currentHost write -globalDomain NSStatusItemSpacing -int 10
    sudo -u yanlin defaults write -globalDomain NSUserKeyEquivalents -dict-add Minimize '\0'
    sudo -u yanlin defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool false
    sudo -u yanlin defaults write com.apple.Spotlight EnabledPreferenceRules -array "Custom.relatedContents"
    sudo -u yanlin defaults write com.apple.Spotlight PasteboardHistoryEnabled -int 0

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  launchd.user.agents.remap-keys = {
    serviceConfig = {
      ProgramArguments = [
        "/usr/bin/hidutil"
        "property"
        "--set"
        ''{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0},{"HIDKeyboardModifierMappingSrc":0x7000000E4,"HIDKeyboardModifierMappingDst":0x700000039}]}''
      ];
      RunAtLoad = true;
      KeepAlive = false;
      Label = "org.nixos.remap-keys";
      StandardErrorPath = "/tmp/remap-keys.err";
      StandardOutPath = "/tmp/remap-keys.out";
    };
  };

}
