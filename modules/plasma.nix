{ config, pkgs, lib, ... }:

{
  # Enable plasma configuration
  programs.plasma.enable = true;
  
  # Configure Konsole through plasma-manager
  programs.konsole = {
    enable = true;
    defaultProfile = "Main";
    profiles.Main = {
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 14;
      };
      colorScheme = "Breeze";
      extraConfig = {
        General.SilenceSeconds = 0;
        "Scrolling".ScrollBarPosition = 0;
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
    }
  ];
}
