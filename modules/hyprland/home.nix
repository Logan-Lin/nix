{ config, pkgs, ... }:

{
  # Fcitx5 input method configuration
  xdg.configFile."fcitx5/profile" = {
    force = true;
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIMName=keyboard-us

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [Groups/0/Items/2]
      Name=mozc
      Layout=

      [GroupOrder]
      0=Default
    '';
  };

  xdg.configFile."fcitx5/config" = {
    force = true;
    text = ''
      [Hotkey]
      TriggerKeys=
      EnumerateWithTriggerKeys=True
      AltTriggerKeys=
      EnumerateForwardKeys=
      EnumerateBackwardKeys=
      EnumerateSkipFirst=False

      [Behavior]
      ActiveByDefault=False
      ShareInputState=No
    '';
  };

  # Rime configuration for Simplified Chinese (must be in .local/share not .config)
  xdg.dataFile."fcitx5/rime/default.custom.yaml" = {
    force = true;
    text = ''
      patch:
        schema_list:
          - schema: luna_pinyin_simp
        menu/page_size: 7
    '';
  };

  # Rime addon configuration - 7 candidates per page
  xdg.configFile."fcitx5/conf/rime.conf" = {
    force = true;
    text = ''
      [InputMethod]
      PageSize=7
    '';
  };

  # Mozc addon configuration - 7 candidates per page
  xdg.configFile."fcitx5/conf/mozc.conf" = {
    force = true;
    text = ''
      [InputMethod]
      PageSize=7
    '';
  };

  # GNOME Keyring for storing WiFi passwords and other secrets
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Source nwg-displays generated monitor configuration
    extraConfig = ''
      source = ~/.config/hypr/monitors.conf
    '';

    settings = {
      # Monitor configuration handled by nwg-displays (see extraConfig above)

      # Environment variables for input methods and theming
      env = [
        "GTK_IM_MODULE,fcitx"
        "QT_IM_MODULE,fcitx"
        "XMODIFIERS,@im=fcitx"
        "GTK_THEME,Adwaita:dark"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_DISABLE_RDD_SANDBOX,1"
      ];

      # Execute apps at launch
      exec-once = [
        "gnome-keyring-daemon --start --components=secrets,ssh"
        "fcitx5 -d"
        "hypridle"
        "swaync"
        "waybar"
        "nm-applet --indicator"
        "mkdir -p ~/Pictures/Screenshots"
        "wl-paste --watch cliphist store"
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
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = "rgba(fabd2fee) rgba(fe8019ee) 45deg";
        "col.inactive_border" = "rgba(928374aa)";
        layout = "dwindle";
      };

      # Decoration settings
      decoration = {
        rounding = 0;
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
        };
        shadow = {
          enabled = false;
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
        disable_hyprland_logo = false;
      };

      # Keybindings
      bind = [
        # Core window management
        "SUPER, Q, killactive,"
        "SUPER, F, fullscreen,"
        "SUPER, V, togglefloating,"

        # Application launchers
        "SUPER, Return, exec, ghostty"
        "SUPER, Space, exec, wofi --show drun"
        "SUPER, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        # Input method switching (cycles through configured IMs)
        "CTRL, Space, exec, ${pkgs.writeShellScript "fcitx5-cycle" ''
          current=$(${pkgs.fcitx5}/bin/fcitx5-remote -n)
          case "$current" in
            keyboard-us)
              ${pkgs.fcitx5}/bin/fcitx5-remote -s rime
              ;;
            rime)
              ${pkgs.fcitx5}/bin/fcitx5-remote -s mozc
              ;;
            mozc|*)
              ${pkgs.fcitx5}/bin/fcitx5-remote -s keyboard-us
              ;;
          esac
        ''}"

        # Window focus navigation (vim-style)
        "SUPER, h, movefocus, l"
        "SUPER, j, movefocus, d"
        "SUPER, k, movefocus, u"
        "SUPER, l, movefocus, r"

        # Window resizing
        "SUPER SHIFT, h, resizeactive, -50 0"
        "SUPER SHIFT, j, resizeactive, 0 50"
        "SUPER SHIFT, k, resizeactive, 0 -50"
        "SUPER SHIFT, l, resizeactive, 50 0"

        # Window swapping/moving
        "SUPER CTRL, h, movewindow, l"
        "SUPER CTRL, j, movewindow, d"
        "SUPER CTRL, k, movewindow, u"
        "SUPER CTRL, l, movewindow, r"

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

        # Brightness control
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        # Volume control
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        # Screenshots
        ", Print, exec, grimblast copysave area ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
        "SHIFT, Print, exec, grimblast copysave screen ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
        "CTRL, Print, exec, grimblast copysave active ~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
      ];

      # Mouse bindings
      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];

      # Lid switch bindings - disable internal display when lid closes, reload config when lid opens
      bindl = [
        ", switch:on:Lid Switch, exec, hyprctl keyword monitor \"eDP-1, disable\""
        ", switch:off:Lid Switch, exec, hyprctl reload"
      ];
    };
  };

  # Hyprpaper wallpaper service
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        "/home/yanlin/Documents/Library/nixos-nineish-dark@4k.png"
      ];
      wallpaper = [
        ",/home/yanlin/Documents/Library/nixos-nineish-dark@4k.png"
      ];
    };
  };

  # Blueman applet for Bluetooth management
  services.blueman-applet.enable = true;

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
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Qt theme settings for consistent theming with GTK
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # dconf settings for GNOME apps to prefer dark theme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    grimblast
    xfce.thunar
    evince
    loupe
    wl-clipboard
    cliphist
    redsocks
  ];

  # Redsocks configuration for transparent SOCKS proxy
  xdg.configFile."redsocks/redsocks.conf" = {
    text = ''
      base {
        log_debug = off;
        log_info = on;
        log = "file:/tmp/redsocks.log";
        daemon = on;
        redirector = iptables;
      }

      redsocks {
        local_ip = 127.0.0.1;
        local_port = 12345;
        ip = 127.0.0.1;
        port = 1080;
        type = socks5;
      }
    '';
  };

  # Hyprland-specific shell configuration
  programs.zsh.initContent = ''
    # Open current directory in Thunar file manager (background)
    open() {
      thunar "''${1:-.}" &>/dev/null &
      disown
    }

    # Quickly restart Hyprland session (graceful logout)
    alias hypr-restart='loginctl terminate-session'

    # SSH tunnel functions for transparent system-wide SOCKS proxy via redsocks
    function tunnel-on() {
      if [[ -z "$1" ]]; then
        echo "Usage: tunnel-on <host>"
        return 1
      fi

      local host="$1"
      local port=1080  # SOCKS port
      local redsocks_port=12345  # Redsocks local port

      # Check if there's already an active tunnel
      local existing_tunnel=$(ps aux | grep -E "ssh -D $port" | grep -v grep)
      if [[ -n "$existing_tunnel" ]]; then
        echo "Existing tunnel detected. Switching to $host..."
        echo "Stopping current tunnel..."
        pkill -f "ssh -D $port"
        sleep 1
      fi

      echo "Starting SOCKS tunnel to $host on port $port..."

      # Start SSH tunnel in background
      ssh -D $port -N -f "$host"
      if [[ $? -ne 0 ]]; then
        echo "✗ Failed to establish tunnel to $host"
        return 1
      fi
      echo "✓ Tunnel established"

      # Start redsocks
      echo "Starting redsocks transparent proxy..."
      redsocks -c ~/.config/redsocks/redsocks.conf
      if [[ $? -ne 0 ]]; then
        echo "✗ Failed to start redsocks"
        pkill -f "ssh -D $port"
        return 1
      fi
      echo "✓ Redsocks started"

      # Configure iptables rules for transparent proxying
      echo "Configuring iptables rules..."

      # Create REDSOCKS chain if it doesn't exist
      sudo iptables -t nat -N REDSOCKS 2>/dev/null || sudo iptables -t nat -F REDSOCKS

      # Exclude localhost and private networks
      sudo iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
      sudo iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
      sudo iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN

      # Redirect all other TCP traffic to redsocks
      sudo iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports $redsocks_port

      # Apply the REDSOCKS chain to OUTPUT
      sudo iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

      echo "✓ System-wide proxy enabled (localhost:$port -> $host)"
      echo "All TCP traffic is now routed through the SSH tunnel"
    }

    function tunnel-off() {
      local port=1080

      echo "Removing iptables rules..."
      # Remove REDSOCKS chain from OUTPUT
      sudo iptables -t nat -D OUTPUT -p tcp -j REDSOCKS 2>/dev/null
      # Flush and delete REDSOCKS chain
      sudo iptables -t nat -F REDSOCKS 2>/dev/null
      sudo iptables -t nat -X REDSOCKS 2>/dev/null
      echo "✓ iptables rules removed"

      echo "Stopping redsocks..."
      pkill -f "redsocks -c"
      echo "✓ Redsocks stopped"

      echo "Stopping SSH tunnels..."
      pkill -f "ssh -D $port"
      echo "✓ SSH tunnels stopped"

      echo "System-wide proxy disabled"
    }

    function tunnel-status() {
      local port=1080
      local redsocks_port=12345

      echo "=== SSH Tunnel Status ==="
      local tunnels=$(ps aux | grep -E "ssh -D $port" | grep -v grep)
      if [[ -n "$tunnels" ]]; then
        echo "✓ Active SSH tunnel:"
        echo "$tunnels"
      else
        echo "✗ No active SSH tunnels"
      fi

      echo ""
      echo "=== Redsocks Status ==="
      local redsocks=$(ps aux | grep -E "redsocks -c" | grep -v grep)
      if [[ -n "$redsocks" ]]; then
        echo "✓ Redsocks running:"
        echo "$redsocks"
      else
        echo "✗ Redsocks not running"
      fi

      echo ""
      echo "=== iptables REDSOCKS Chain ==="
      if sudo iptables -t nat -L REDSOCKS -n 2>/dev/null | grep -q "Chain REDSOCKS"; then
        echo "✓ REDSOCKS chain exists:"
        sudo iptables -t nat -L REDSOCKS -n --line-numbers
      else
        echo "✗ REDSOCKS chain not configured"
      fi

      echo ""
      echo "=== Network Test ==="
      echo "Your current IP (via proxy if enabled):"
      timeout 5 curl -s https://api.ipify.org 2>/dev/null || echo "Failed to fetch IP"
    }
  '';

  # Cursor theme configuration
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Wofi application launcher configuration
  programs.wofi = {
    enable = true;
    settings = {
      # Vim-style navigation with Ctrl+j/k
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
    };
  };

  # Waybar configuration for Hyprland
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "custom/nixos-logo" "clock" ];
        modules-right = [ "custom/notification" "pulseaudio" "backlight" "battery" "tray" ];

        "custom/nixos-logo" = {
          format = "";
          tooltip = true;
          tooltip-format = "NixOS";
        };

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        "clock" = {
          format = "{:%H:%M %a %d %b}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };

        "battery" = {
          bat = "BAT0";
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-icons = ["" "" "" "" ""];
          tooltip-format = "{capacity}% • {timeTo}";
        };

        "pulseaudio" = {
          format = "{volume}% {icon}";
          format-bluetooth = "{volume}% {icon}";
          format-muted = "{volume}X {icon}";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = ["" "" ""];
          };
          on-click = "pavucontrol";
          tooltip-format = "Volume: {volume}%";
        };

        "backlight" = {
          device = "intel_backlight";
          format = "{percent}% {icon}";
          format-icons = ["" ""];
          on-click = "nwg-displays";
          tooltip-format = "Brightness: {percent}%";
        };

        "tray" = {
          spacing = 10;
        };

        "custom/notification" = {
          tooltip = false;
          format = "{} {icon}";
          format-icons = {
            notification = "<span foreground='#f38ba8'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='#f38ba8'> <sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='#f38ba8'> <sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='#f38ba8'> <sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "sleep 0.1 && swaync-client -t -sw";
          on-click-right = "sleep 0.1 && swaync-client -d -sw";
          escape = true;
        };
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: monospace;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(43, 48, 59, 0.9);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
      }

      #workspaces button.active {
        background-color: #64727D;
      }

      #workspaces button:hover {
        background-color: rgba(0, 0, 0, 0.2);
      }

      #window,
      #clock,
      #tray {
        padding: 0 10px;
        color: #ffffff;
      }

      /* NixOS logo styling */
      #custom-nixos-logo {
        padding: 0;
        margin: 0 5px;
        color: #5277C3;  /* NixOS Blue */
        font-size: 16px;
      }

      /* Notification module styling */
      #custom-notification {
        padding: 0 10px;
        color: #f38ba8;  /* Pink/Red - Notifications */
      }

      /* Color-coded modules for easy distinction */
      #pulseaudio {
        padding: 0 10px;
        color: #a6e3a1;  /* Green - Volume */
      }

      #backlight {
        padding: 0 10px;
        color: #f9e2af;  /* Yellow - Brightness */
      }

      #battery {
        padding: 0 10px;
        color: #89b4fa;  /* Blue - Battery */
      }

      @keyframes blink {
        to {
          opacity: 0.5;
        }
      }

    '';
  };
}
