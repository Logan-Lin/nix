{ config, pkgs, lib, ... }:

let
  toLua = lib.generators.toLua { };

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";

  # hyprctl dispatch evaluates its argument as a Lua dispatcher expression.
  dpms = action: "${hyprctl} dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";

  # Pick a window from all workspaces through a wofi menu and focus it.
  windowSwitcher = pkgs.writeShellScript "hypr-window-switcher" ''
    address=$(${hyprctl} clients -j \
      | ${pkgs.jq}/bin/jq -r '.[] | select(.workspace.id > 0) | "\(.address)|\(.class): \(.title)"' \
      | ${pkgs.wofi}/bin/wofi --dmenu --prompt "window" \
      | ${pkgs.coreutils}/bin/cut -d'|' -f1)
    [ -n "$address" ] || exit 0
    ${hyprctl} dispatch "hl.dsp.focus({ window = \"address:$address\" })"
  '';

  screenshot = target: "grimblast copysave ${target} ~/Downloads/Screenshot_$(date +%Y-%m-%d_%H-%M-%S).png";

  execBinds = {
    "SUPER + T" = "ghostty";
    "SUPER + Space" = "wofi --show drun";
    "SUPER + Tab" = "${windowSwitcher}";
    "SUPER + C" = "cliphist list | wofi --dmenu | cliphist decode | wl-copy";

    "XF86MonBrightnessUp" = "brightnessctl set +5%";
    "XF86MonBrightnessDown" = "brightnessctl set 5%-";

    "XF86AudioRaiseVolume" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
    "XF86AudioLowerVolume" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
    "XF86AudioMute" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    "XF86AudioMicMute" = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

    "Print" = screenshot "area";
    "SHIFT + Print" = screenshot "screen";
    "CTRL + Print" = screenshot "active";
  };

  # UWSM exports the session environment and runs the XDG autostart entries, which start the keyring, nm-applet, blueman-applet, and fcitx5.
  # swaync starts through D-Bus activation.
  startupCommands = [
    "waybar"
    "${pkgs.swaybg}/bin/swaybg -c '#000000'"
    "mkdir -p ~/Downloads"
    "wl-paste --watch cliphist store"
  ];

  hy3Config = {
    general.layout = "hy3";

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
  };

  evinceDesktop = "org.gnome.Evince.desktop";
  loupeDesktop = "org.gnome.Loupe.desktop";
  mpvDesktop = "mpv.desktop";
  codiumDesktop = "codium.desktop";
  obsidianDesktop = "md.obsidian.Obsidian.desktop";
  inkscapeDesktop = "org.inkscape.Inkscape.desktop";
  drawioDesktop = "drawio.desktop";

  textMimeTypes = [
    "text/plain"
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

  markdownMimeTypes = [
    "text/markdown"
    "text/x-markdown"
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
  services.hyprpolkitagent.enable = true;

  # Override the system autostart entry so nm-applet runs as a tray indicator, the only kind waybar shows.
  xdg.configFile."autostart/nm-applet.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=NetworkManager Applet
    Icon=nm-device-wireless
    Exec=nm-applet --indicator
    Terminal=false
    NoDisplay=true
    NotShowIn=KDE;GNOME;COSMIC;
    X-GNOME-UsesNotifications=true
  '';

  # monitors.lua is written at runtime by nwg-displays and stays outside home-manager.
  # Create an empty one when it is missing so the require call in the Hyprland config below does not fail.
  home.activation.ensureHyprMonitorsLua = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/hypr"
    [ -e "$HOME/.config/hypr/monitors.lua" ] || touch "$HOME/.config/hypr/monitors.lua"
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    # Hyprland no longer reads the hyprlang format, only hyprland.lua.
    configType = "lua";
    # UWSM manages the session targets, and the module's own systemd integration conflicts with it.
    systemd.enable = false;
    # The NixOS module provides the portals.
    # A portal here would point the portal directory at the home profile, hiding the GTK and keyring portals installed by the system.
    portalPackage = null;
    plugins = [ pkgs.hyprlandPlugins.hy3 ];

    settings = {
      # Fallback rule for any output, overridden by the rules in monitors.lua.
      monitor = {
        output = "";
        mode = "preferred";
        position = "auto";
        scale = "auto";
      };

      env = lib.mapAttrsToList (name: value: { _args = [ name value ]; }) {
        GTK_THEME = "Adwaita:dark";
        XCURSOR_SIZE = "24";
        XCURSOR_THEME = "Bibata-Modern-Ice";
        MOZ_ENABLE_WAYLAND = "1";
        NIXOS_OZONE_WL = "1";
      };

      config = {
        input = {
          kb_layout = "us";
          follow_mouse = 1;
          sensitivity = 0.5;
          accel_profile = "flat";
          touchpad = {
            natural_scroll = true;
            tap_to_click = false;
            disable_while_typing = true;
          };
        };

        general = {
          gaps_in = 0;
          gaps_out = 0;
          border_size = 2;
          col = {
            active_border = {
              colors = [ "rgba(fabd2fee)" "rgba(fe8019ee)" ];
              angle = 45;
            };
            inactive_border = "rgba(928374aa)";
          };
        };

        decoration = {
          rounding = 0;
          blur.enabled = false;
          shadow.enabled = false;
        };

        animations.enabled = true;

        dwindle.preserve_split = true;

        misc = {
          force_default_wallpaper = 0;
          disable_splash_rendering = true;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };
      };

      curve._args = [
        "myBezier"
        { type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; }
      ];

      animation = [
        { leaf = "windows"; enabled = true; speed = 3; bezier = "myBezier"; }
        { leaf = "windowsOut"; enabled = true; speed = 3; bezier = "default"; style = "popin 80%"; }
        { leaf = "border"; enabled = true; speed = 5; bezier = "default"; }
        { leaf = "borderangle"; enabled = true; speed = 4; bezier = "default"; }
        { leaf = "fade"; enabled = true; speed = 3; bezier = "default"; }
        { leaf = "workspaces"; enabled = true; speed = 3; bezier = "default"; }
      ];
    };

    extraConfig = ''
      require("monitors")

      -- hy3 registers its options and dispatchers only once loaded, after the first config pass, and Hyprland then reloads the config.
      -- Until then, fall back to the built-in layout and dispatchers.
      local hy3 = hl.plugin.hy3

      if hy3 then
        hl.config(${toLua hy3Config})
      end

      local function focus(dir)
        return hy3 and hy3.move_focus(dir) or hl.dsp.focus({ direction = dir })
      end

      local function move(dir)
        return hy3 and hy3.move_window(dir) or hl.dsp.window.move({ direction = dir })
      end

      hl.bind("SUPER + Return", hl.dsp.window.float({ action = "toggle" }))
      if hy3 then
        hl.bind("SUPER + N", hy3.change_group("tab"))
        hl.bind("SUPER + M", hy3.change_group("untab"))
      end
      hl.bind("SUPER + F", hl.dsp.window.fullscreen())
      hl.bind("SUPER + Q", hl.dsp.window.close())

      for keys, cmd in pairs(${toLua execBinds}) do
        hl.bind(keys, hl.dsp.exec_cmd(cmd))
      end

      for key, dir in pairs({ h = "l", j = "d", k = "u", l = "r" }) do
        hl.bind("SUPER + " .. key, focus(dir))
        hl.bind("SUPER + SHIFT + " .. key, move(dir))
      end

      hl.bind("SUPER + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
      hl.bind("SUPER + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
      hl.bind("SUPER + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
      hl.bind("SUPER + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))

      -- Key 0 maps to workspace 10.
      for i = 1, 10 do
        hl.bind("SUPER + " .. i % 10, hl.dsp.focus({ workspace = i }))
        hl.bind("SUPER + SHIFT + " .. i % 10, hl.dsp.window.move({ workspace = i }))
      end

      hl.bind("SUPER + comma", hl.dsp.focus({ monitor = "-1" }))
      hl.bind("SUPER + period", hl.dsp.focus({ monitor = "+1" }))
      hl.bind("SUPER + SHIFT + comma", hl.dsp.workspace.move({ monitor = "-1" }))
      hl.bind("SUPER + SHIFT + period", hl.dsp.workspace.move({ monitor = "+1" }))

      hl.bind("mouse:274", hl.dsp.no_op())

      hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

      hl.on("hyprland.start", function()
        for _, cmd in ipairs(${toLua startupCommands}) do
          hl.exec_cmd(cmd)
        end
      end)
    '';
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = dpms "on";
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
          on-timeout = dpms "off";
          on-resume = dpms "on";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general.hide_cursor = true;

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
    # gnome-themes-extra ships no GTK 4 theme, and GTK 4 apps follow the dark color scheme set through dconf below.
    gtk4.theme = null;
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
      (lib.genAttrs textMimeTypes (_: codiumDesktop)) //
      (lib.genAttrs markdownMimeTypes (_: obsidianDesktop)) //
      {
        "image/svg+xml" = inkscapeDesktop;
        "application/vnd.jgraph.mxfile" = drawioDesktop;
      };
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
