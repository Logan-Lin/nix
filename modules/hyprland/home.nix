# Full Hyprland Wayland desktop for a Linux host.
# A host opts in by importing this module.
# It starts the compositor with its keybindings and autostart programs, adds idle dimming and screen locking through hypridle and hyprlock, sets the wallpaper through hyprpaper, applies GTK and Qt dark theming, and provides a waybar status bar, a wofi launcher, and default applications for common file types.

{ config, pkgs, lib, ... }:

let
  # Pick a window from all workspaces through a wofi menu and focus it.
  windowSwitcher = pkgs.writeShellScript "hypr-window-switcher" ''
    ${pkgs.hyprland}/bin/hyprctl clients -j \
      | ${pkgs.jq}/bin/jq -r '.[] | select(.workspace.id > 0) | "\(.address)|\(.class): \(.title)"' \
      | ${pkgs.wofi}/bin/wofi --dmenu --prompt "window" \
      | ${pkgs.coreutils}/bin/cut -d'|' -f1 \
      | ${pkgs.findutils}/bin/xargs -r -I{} ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow address:{}
  '';

  evinceDesktop = "org.gnome.Evince.desktop";
  loupeDesktop = "org.gnome.Loupe.desktop";
  mpvDesktop = "mpv.desktop";
  nvimDesktop = "nvim-ghostty.desktop";

  textMimeTypes = [
    "text/plain"
    "text/markdown"
    "text/x-python"
    "application/javascript"
    "application/typescript"
    "application/json"
    "application/yaml"
    "application/x-yaml"
    "application/toml"
    "application/xml"
    "text/xml"
    "text/css"
    "text/csv"
    "application/x-shellscript"
    "text/x-shellscript"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/rust"
    "text/x-go"
    "text/x-java"
    "application/x-ruby"
    "application/x-php"
    "text/x-lua"
    "text/x-tex"
    "text/x-bibtex"
    "text/x-vim"
  ];

  imageMimeTypes = [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/bmp"
    "image/tiff"
    "image/webp"
    "image/heic"
    "image/heif"
    "image/vnd.microsoft.icon"
    "image/x-icon"
  ];

  mediaMimeTypes = [
    "video/mp4"
    "video/x-matroska"
    "video/x-msvideo"
    "video/quicktime"
    "video/x-ms-wmv"
    "video/x-flv"
    "video/webm"
    "video/x-m4v"
    "video/mpeg"
    "audio/mpeg"
    "audio/mp4"
    "audio/flac"
    "audio/x-wav"
    "audio/wav"
    "audio/aac"
    "audio/ogg"
    "audio/x-opus+ogg"
    "audio/opus"
  ];
in

{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" "ssh" ];
  };

  # monitors.conf is written at runtime by nwg-displays and stays outside home-manager.
  # Create an empty one when it is missing so the source directive in the Hyprland config below does not fail.
  home.activation.ensureHyprMonitorsConf = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/hypr"
    [ -e "$HOME/.config/hypr/monitors.conf" ] || touch "$HOME/.config/hypr/monitors.conf"
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "hyprlang";
    plugins = [ pkgs.hyprlandPlugins.hy3 ];

    extraConfig = ''
      source = ~/.config/hypr/monitors.conf
    '';

    settings = {
      env = [
        "GTK_THEME,Adwaita:dark"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Ice"
        "MOZ_ENABLE_WAYLAND,1"
        "NIXOS_OZONE_WL,1"
      ];

      exec-once = [
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE"
        "systemctl --user start hyprpolkitagent"
        "gnome-keyring-daemon --start --components=secrets,ssh"
        "swaync"
        "waybar"
        "nm-applet --indicator"
        "blueman-applet"
        "fcitx5 -d --replace"
        "mkdir -p ~/Downloads"
        "wl-paste --watch cliphist store"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0.5;
        accel_profile = "flat";
        touchpad = {
          natural_scroll = true;
          tap-to-click = false;
          disable_while_typing = true;
        };
      };

      general = {
        gaps_in = 0;
        gaps_out = 0;
        border_size = 2;
        "col.active_border" = "rgba(fabd2fee) rgba(fe8019ee) 45deg";
        "col.inactive_border" = "rgba(928374aa)";
        layout = "hy3";
      };

      plugin.hy3 = {
        tab_first_window = true;

        tabs = {
          height = 30;
          padding = 6;
          radius = 0;
          border_width = 2;
          blur = false;
        };
      };

      decoration = {
        rounding = 0;
        blur.enabled = false;
        shadow.enabled = false;
      };

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

      dwindle = {
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_splash_rendering = true;
      };

      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      bind = [
        "SUPER, Return, togglefloating,"
        "SUPER, N, hy3:changegroup, tab"
        "SUPER, M, hy3:changegroup, untab"
        "SUPER, F, fullscreen,"
        "SUPER, Q, killactive,"

        "SUPER, T, exec, ghostty"
        "SUPER, Space, exec, wofi --show drun"
        "SUPER, Tab, exec, ${windowSwitcher}"
        "SUPER, C, exec, cliphist list | wofi --dmenu | cliphist decode | wl-copy"

        "SUPER, h, hy3:movefocus, l"
        "SUPER, j, hy3:movefocus, d"
        "SUPER, k, hy3:movefocus, u"
        "SUPER, l, hy3:movefocus, r"

        "SUPER SHIFT, h, hy3:movewindow, l"
        "SUPER SHIFT, j, hy3:movewindow, d"
        "SUPER SHIFT, k, hy3:movewindow, u"
        "SUPER SHIFT, l, hy3:movewindow, r"

        "SUPER, left, resizeactive, -50 0"
        "SUPER, right, resizeactive, 50 0"
        "SUPER, up, resizeactive, 0 -50"
        "SUPER, down, resizeactive, 0 50"

        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"
        "SUPER, 0, workspace, 10"

        "SUPER SHIFT, 1, movetoworkspace, 1"
        "SUPER SHIFT, 2, movetoworkspace, 2"
        "SUPER SHIFT, 3, movetoworkspace, 3"
        "SUPER SHIFT, 4, movetoworkspace, 4"
        "SUPER SHIFT, 5, movetoworkspace, 5"
        "SUPER SHIFT, 6, movetoworkspace, 6"
        "SUPER SHIFT, 7, movetoworkspace, 7"
        "SUPER SHIFT, 8, movetoworkspace, 8"
        "SUPER SHIFT, 9, movetoworkspace, 9"
        "SUPER SHIFT, 0, movetoworkspace, 10"

        "SUPER, comma, focusmonitor, -1"
        "SUPER, period, focusmonitor, +1"
        "SUPER SHIFT, comma, movecurrentworkspacetomonitor, -1"
        "SUPER SHIFT, period, movecurrentworkspacetomonitor, +1"

        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"

        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"

        ", Print, exec, grimblast copysave area ~/Downloads/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        "SHIFT, Print, exec, grimblast copysave screen ~/Downloads/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
        "CTRL, Print, exec, grimblast copysave active ~/Downloads/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"

        ", mouse:274, exec, true"
      ];

      bindm = [
        "SUPER, mouse:272, movewindow"
        "SUPER, mouse:273, resizewindow"
      ];
    };
  };

  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      preload = [ "${config.home.homeDirectory}/Documents/app-state/nixos-nineish-dark.png" ];
      wallpaper = [{
        monitor = "";
        path = "${config.home.homeDirectory}/Documents/app-state/nixos-nineish-dark.png";
      }];
    };
  };

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
          timeout = 540;
          on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 5%";
          on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
        }
        { timeout = 600; on-timeout = "loginctl lock-session"; }
        {
          timeout = 900;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };

      background = [{
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
      }];

      input-field = [{
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
      }];
    };
  };

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
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4 = {
      theme = config.gtk.theme;
      extraConfig.gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  xfconf.settings.thunar = {
    "default-view" = "ThunarDetailsView";
    "misc-date-style" = "THUNAR_DATE_STYLE_YYYYMMDD";
    "last-show-hidden" = false;
  };

  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6
    adwaita-icon-theme
    hicolor-icon-theme
    grimblast
    wl-clipboard
    cliphist

    thunar
    evince
    loupe
    mpv
  ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      (lib.genAttrs [ "application/pdf" ] (_: evinceDesktop)) //
      (lib.genAttrs imageMimeTypes (_: loupeDesktop)) //
      (lib.genAttrs mediaMimeTypes (_: mpvDesktop)) //
      (lib.genAttrs textMimeTypes (_: nvimDesktop));
  };

  xdg.desktopEntries.nvim-ghostty = {
    name = "Neovim (Ghostty)";
    genericName = "Text Editor";
    exec = "ghostty -e nvim %F";
    terminal = false;
    categories = [ "Utility" "TextEditor" ];
    mimeType = textMimeTypes;
  };

  programs.zsh.initContent = ''
    alias hypr-restart='loginctl terminate-session'
  '';

  home.pointerCursor = {
    enable = true;
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.wofi = {
    enable = true;
    settings = {
      key_up = "Ctrl-k";
      key_down = "Ctrl-j";
      insensitive = true;
    };
  };

  programs.waybar = {
    enable = true;
    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "custom/notification" "pulseaudio" "backlight" "battery" "tray" ];

      "hyprland/workspaces" = {
        format = "{name}";
        on-click = "activate";
      };

      "hyprland/window" = {
        format = "{}";
        max-length = 50;
      };

      clock = {
        format = "{:%H:%M %a %d %b}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      battery = {
        states = { warning = 30; critical = 15; };
        format = "{capacity}% {icon}";
        format-charging = "{capacity}% ";
        format-plugged = "{capacity}% ";
        format-icons = ["" "" "" "" ""];
        tooltip-format = "{capacity}% • {timeTo}";
      };

      pulseaudio = {
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

      backlight = {
        format = "{percent}% {icon}";
        format-icons = ["" ""];
        on-click = "nwg-displays";
        tooltip-format = "Brightness: {percent}%";
      };

      tray.spacing = 10;

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

      #custom-notification {
        padding: 0 10px;
        color: #f38ba8;
      }

      #pulseaudio {
        padding: 0 10px;
        color: #a6e3a1;
      }

      #backlight {
        padding: 0 10px;
        color: #f9e2af;
      }

      #battery {
        padding: 0 10px;
        color: #89b4fa;
      }

      @keyframes blink {
        to { opacity: 0.5; }
      }
    '';
  };
}
