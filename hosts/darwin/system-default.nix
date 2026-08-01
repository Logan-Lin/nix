# macOS platform default for the system configuration.
# Imports the cross-platform system default and layers on the macOS settings every host shares.

{ config, pkgs, inputs, ... }:

{
  imports = [
    ../system-default.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew = {
    enable = true;
    user = "yanlin";
    trust.taps = [ "nikitabobko/tap" ];
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
      upgrade = true;
      extraFlags = [ "--force-cleanup" "--zap" ];
      extraEnv = {
        HOMEBREW_NO_ANALYTICS = "1";
        HOMEBREW_NO_ANALYTICS_MESSAGE_OUTPUT = "1";
        HOMEBREW_NO_ENV_HINTS = "1";
        HOMEBREW_NO_UPDATE_REPORT_NEW = "1";
      };
    };
    taps = [
      "nikitabobko/tap"
    ];
    casks = [
      "nikitabobko/tap/aerospace"
      "clash-verge-rev"
      "tailscale-app"
      "drawio"
      "firefox"
      "ungoogled-chromium"
      "ghostty"
      "iina"
      "inkscape"
      "keepassxc"
      "linearmouse"
      "localsend"
      "maccy"
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"
      "musicbrainz-picard"
      "obsidian"
      "ovito"
      "slidepilot"
      "tencent-meeting"
      "wechat"
      "adobe-acrobat-reader"
      "keycastr"
    ];
  };

  system.stateVersion = 6;
  nixpkgs.hostPlatform = "aarch64-darwin";

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

      # 1 disables the hot corner action, applied to all four corners.
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
      AppleShowScrollBars = "WhenScrolling";
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
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

    chflags hidden /Users/yanlin/{Desktop,Applications,Movies,Music,Pictures,Public}
  '';

  launchd.user.agents.remap-keys = {
    serviceConfig = {
      ProgramArguments =
        let
          capsLock = 30064771129;
          leftControl = 30064771296;
          rightControl = 30064771300;
        in [
          "/usr/bin/hidutil"
          "property"
          "--set"
          (builtins.toJSON {
            UserKeyMapping = [
              { HIDKeyboardModifierMappingSrc = capsLock; HIDKeyboardModifierMappingDst = leftControl; }
              { HIDKeyboardModifierMappingSrc = rightControl; HIDKeyboardModifierMappingDst = capsLock; }
            ];
          })
        ];
      RunAtLoad = true;
      KeepAlive = false;
      Label = "org.nixos.remap-keys";
      StandardErrorPath = "/tmp/remap-keys.err";
      StandardOutPath = "/tmp/remap-keys.out";
    };
  };

}
