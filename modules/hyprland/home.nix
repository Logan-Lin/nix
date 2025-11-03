{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    settings = {
      # Monitor configuration
      monitor = ",preferred,auto,1";

      # Environment variables for input methods
      env = [
        "GTK_IM_MODULE,ibus"
        "QT_IM_MODULE,ibus"
        "XMODIFIERS,@im=ibus"
      ];

      # Execute apps at launch
      exec-once = [
        "ibus-daemon -drx"
        "hypridle"
      ];

      # Input configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = false;
          disable_while_typing = true;
        };
      };

      # General window and workspace settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Decoration settings
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
      };

      # Animation settings
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 3, myBezier"
          "windowsOut, 1, 3, default, popin 80%"
          "border, 1, 5, default"
          "borderangle, 1, 4, default"
          "fade, 1, 3, default"
          "workspaces, 1, 3, default"
        ];
      };

      # Dwindle layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Master layout settings
      master = {
        new_status = "master";
      };

      # Misc settings
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      # Keybindings
      bind = [
        # Core window management
        "SUPER, Q, killactive,"
        "SUPER, F, fullscreen,"
        "SUPER, V, togglefloating,"

        # Vim-style window tiling (replicate GNOME behavior)
        # Super+h: Tile window to left half
        "SUPER, h, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 100% && hyprctl dispatch moveactive exact 0 0 && hyprctl dispatch togglefloating"

        # Super+l: Tile window to right half
        "SUPER, l, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 100% && hyprctl dispatch moveactive exact 50% 0 && hyprctl dispatch togglefloating"

        # Super+k: Maximize window (fullscreen mode 1 - keeps gaps/bars)
        "SUPER, k, fullscreen, 1"

        # Super+j: Restore window from fullscreen
        "SUPER, j, fullscreen, 0"

        # Quarter-corner tiling
        # Super+r: Top-left quarter
        "SUPER, r, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 50% && hyprctl dispatch moveactive exact 0 0 && hyprctl dispatch togglefloating"

        # Super+t: Top-right quarter
        "SUPER, t, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 50% && hyprctl dispatch moveactive exact 50% 0 && hyprctl dispatch togglefloating"

        # Super+c: Bottom-left quarter (changed from 'f' to avoid conflict with fullscreen)
        "SUPER, c, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 50% && hyprctl dispatch moveactive exact 0 50% && hyprctl dispatch togglefloating"

        # Super+g: Bottom-right quarter
        "SUPER, g, exec, hyprctl dispatch togglefloating && hyprctl dispatch resizeactive exact 50% 50% && hyprctl dispatch moveactive exact 50% 50% && hyprctl dispatch togglefloating"

        # Move windows between monitors
        "SUPER SHIFT, h, movecurrentworkspacetomonitor, l"
        "SUPER SHIFT, l, movecurrentworkspacetomonitor, r"
        "SUPER SHIFT, k, movecurrentworkspacetomonitor, u"
        "SUPER SHIFT, j, movecurrentworkspacetomonitor, d"

        # Workspace navigation (1-9)
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        # Move window to workspace (1-9)
        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"

        # Input method switching
        "SUPER, Space, exec, ibus engine xkb:us::eng"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
  };

  # Hypridle configuration (screen timeout and lock)
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 600; # 10 minutes
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900; # 15 minutes
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  # Hyprlock configuration (screen locker)
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          position = "0, -20";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(202, 211, 245)";
          inner_color = "rgb(91, 96, 120)";
          outer_color = "rgb(24, 25, 38)";
          outline_thickness = 5;
          placeholder_text = ''<span foreground="##cad3f5">Password...</span>'';
          shadow_passes = 2;
        }
      ];
    };
  };

  # GTK theme settings (optional, for consistent theming)
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
  };
}
