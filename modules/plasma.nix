{ config, pkgs, lib, ... }:

{
  # Enable plasma configuration
  programs.plasma.enable = true;
  
  # Set dark theme
  programs.plasma.workspace.theme = "breeze-dark";
  programs.plasma.workspace.colorScheme = "BreezeDark";
  
  # Configure Konsole through plasma-manager
  programs.konsole = {
    enable = true;
    defaultProfile = "Main";
    profiles.Main = {
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 13;
      };
      colorScheme = "Breeze";
      extraConfig = {
        General.SilenceSeconds = 0;
        "Scrolling".ScrollBarPosition = 2;
        "Terminal Features" = {
          BlinkingTextEnabled = true;
          FlowControlEnabled = true;
        };
      };
    };
    extraConfig = {
      MainWindow = {
        ToolBarsMovable = "Disabled";
      };
      KonsoleWindow.ShowMenuBarByDefault = false;
      MainToolBar.Visible = false;
      SessionToolBar.Visible = false;
      TabBar = {
        TabBarPosition = "Top";
        TabBarVisibility = "ShowTabBarWhenNeeded";
        ShowQuickButtons = false;
        NewTabButton = false;
        CloseTabButton = false;
      };
      General.ShowWindowTitleOnTitleBar = false;
      "Notification Messages".CloseSession = false;
    };
  };

  # Configure KWin for borderless windows
  programs.plasma.kwin.borderlessMaximizedWindows = true;

  # Hide bottom panel/status bar
  programs.plasma.panels = [
    {
      location = "bottom";
      hiding = "autohide";
      widgets = [
        "org.kde.plasma.kickoff"
        {
          iconTasks = {
            launchers = [
              "applications:org.kde.dolphin.desktop"
              "applications:firefox.desktop"
              "applications:obsidian.desktop"
              "applications:com.mitchellh.ghostty.desktop"
              "applications:org.keepassxc.KeePassXC.desktop"
            ];
          };
        }
        "org.kde.plasma.marginsseparator"
        {
          systemTray.items = {
            shown = [
              "org.kde.plasma.bluetooth"
              "org.kde.plasma.battery"
              "org.kde.plasma.networkmanagement"
              "org.kde.plasma.volume"
            ];
          };
        }
        "org.kde.plasma.digitalclock"
      ];
    }
  ];
}
