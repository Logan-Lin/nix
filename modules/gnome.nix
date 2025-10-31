{ config, pkgs, lib, ... }:

let
  # Import gvariant helpers for dconf types
  mkTuple = lib.hm.gvariant.mkTuple;
  mkUint32 = lib.hm.gvariant.mkUint32;
in

{
  # GNOME configuration via dconf
  dconf.settings = {
    # Interface settings
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      cursor-theme = "Adwaita";
    };

    # Touchpad settings
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = false;
      natural-scroll = true;
    };

    # Desktop background
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/yanlin/Documents/Library/nixos-nineish-dark@4k.png";
      picture-uri-dark = "file:///home/yanlin/Documents/Library/nixos-nineish-dark@4k.png";
      picture-options = "scaled";
    };

    # Input sources - US English, Chinese Pinyin, Japanese
    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [ "xkb" "us" ])
        (mkTuple [ "ibus" "libpinyin" ])
        (mkTuple [ "ibus" "mozc-jp" ])
      ];
      xkb-options = [ "" ];
    };

    # GNOME Shell configuration
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "hidetopbar@mathieu.bidon.ca"
        "pano@elhan.io"
        "tiling-assistant@leleat-on-github"
        "rounded-window-corners@fxgn"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "com.mitchellh.ghostty.desktop"
        "firefox.desktop"
        "obsidian.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.Loupe.desktop"
        "org.keepassxc.KeePassXC.desktop"
      ];
    };

    # Hide Top Bar extension configuration
    # Always hide the top bar except in Activities Overview (Super key)
    "org/gnome/shell/extensions/hidetopbar" = {
      enable-intellihide = false;
      enable-active-window = false;
      mouse-sensitive = false;
      mouse-sensitive-fullscreen-window = false;
    };

    # Pano clipboard manager configuration
    "org/gnome/shell/extensions/pano" = {
      send-notification-on-copy = false;  # Disable notification toasts
      play-audio-on-copy = false;  # Disable audio feedback on copy
    };

    # Nautilus (GNOME Files) configuration
    "org/gnome/nautilus/preferences" = {
      show-hidden-files = true;
      default-folder-viewer = "list-view";
    };

    # Disable GNOME Software auto-updates
    "org/gnome/software" = {
      download-updates = false;
      download-updates-notify = false;
    };

    # Notification settings
    "org/gnome/desktop/notifications" = {
      show-banners = false;  # Disable notification popups (still logged in notification center)
    };

    # Sound settings
    "org/gnome/desktop/sound" = {
      event-sounds = false;  # Disable notification sounds
    };

    # Screen timeout settings
    # Setup: ThinkPad laptop (lid closed) + 4K TV as external monitor
    "org/gnome/desktop/session" = {
      idle-delay = mkUint32 900;  # Screen blank after 15 minutes (900 seconds)
    };

    "org/gnome/settings-daemon/plugins/power" = {
      idle-dim = false;  # Don't dim screen before blanking
    };

    # IBus libpinyin (Chinese Pinyin) configuration
    "com/github/libpinyin/ibus-libpinyin/libpinyin" = {
      lookup-table-page-size = 7;  # Number of candidates displayed (default: 5)
    };

    # Tiling Assistant - quarter corner tiling keybindings
    # Mapped to R/T/F/G keys to mirror their physical positions on keyboard
    "org/gnome/shell/extensions/tiling-assistant" = {
      tile-topleft-quarter = [ "<Super>r" ];      # Top-left: Super+R
      tile-topright-quarter = [ "<Super>t" ];     # Top-right: Super+T
      tile-bottomleft-quarter = [ "<Super>f" ];   # Bottom-left: Super+F
      tile-bottomright-quarter = [ "<Super>g" ];  # Bottom-right: Super+G
    };

    # NOTE: vim-style hjkl keybindings (Super+h/j/k/l) are configured at the
    # system level in desktop.nix with lockAll = true to prevent them from
    # being overridden after suspend/resume or by GNOME extensions

  };

  # IBus Mozc (Japanese) configuration - default to Hiragana input mode
  home.file.".config/mozc/ibus_config.textproto".text = ''
    engines {
      name : "mozc-jp"
      longname : "Mozc"
      layout : "default"
      layout_variant : ""
      layout_option : ""
      rank : 80
      symbol : "あ"
      composition_mode : HIRAGANA
    }
    active_on_launch: True
  '';

  # Configure cursor theme system-wide
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Configure GTK theme and icon theme
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
  };

  # Configure XDG user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    # Keep these directories
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";

    # Disable unwanted directories
    music = null;
    pictures = null;
    videos = null;
    publicShare = null;
    templates = null;
  };

  # GNOME Shell extensions and Qt theming packages
  home.packages = with pkgs; [
    gnomeExtensions.hide-top-bar
    gnomeExtensions.pano
    gnomeExtensions.tiling-assistant
    gnomeExtensions.rounded-window-corners-reborn
  ];

  # Custom desktop file for opening text files with Neovim in Ghostty
  home.file.".local/share/applications/nvim-ghostty.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Neovim (Ghostty)
    Comment=Edit text files with Neovim in Ghostty terminal
    Exec=ghostty -e nvim %F
    Terminal=false
    Categories=TextEditor;Utility;
    MimeType=text/plain;text/markdown;text/x-nix;text/x-shellscript;text/x-log;text/csv;text/html;text/css;text/xml;text/x-python;text/x-python3;text/x-c;text/x-c++src;text/x-chdr;text/x-c++hdr;text/x-java;text/x-tex;text/x-latex;application/x-yaml;application/json;application/xml;application/xhtml+xml;application/javascript;application/typescript;application/x-python;application/x-ipynb+json;application/toml;application/x-npy;
    Icon=nvim
  '';

  # Configure default applications for file types
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # PDF documents
      "application/pdf" = "org.gnome.Evince.desktop";

      # Images
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/jpg" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/heic" = "org.gnome.Loupe.desktop";
      "image/heif" = "org.gnome.Loupe.desktop";
      "image/tiff" = "org.gnome.Loupe.desktop";

      # Videos
      "video/mp4" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/ogg" = "vlc.desktop";
      "video/x-flv" = "vlc.desktop";
      "video/3gpp" = "vlc.desktop";

      # Text and code files
      "text/plain" = "nvim-ghostty.desktop";
      "text/markdown" = "nvim-ghostty.desktop";
      "text/x-nix" = "nvim-ghostty.desktop";
      "text/x-shellscript" = "nvim-ghostty.desktop";
      "text/x-log" = "nvim-ghostty.desktop";
      "text/csv" = "nvim-ghostty.desktop";
      "text/html" = "nvim-ghostty.desktop";
      "text/css" = "nvim-ghostty.desktop";
      "text/xml" = "nvim-ghostty.desktop";
      "text/x-python" = "nvim-ghostty.desktop";
      "text/x-python3" = "nvim-ghostty.desktop";
      "text/x-c" = "nvim-ghostty.desktop";
      "text/x-c++src" = "nvim-ghostty.desktop";
      "text/x-chdr" = "nvim-ghostty.desktop";
      "text/x-c++hdr" = "nvim-ghostty.desktop";
      "text/x-java" = "nvim-ghostty.desktop";
      "text/x-tex" = "nvim-ghostty.desktop";
      "text/x-latex" = "nvim-ghostty.desktop";
      "application/x-yaml" = "nvim-ghostty.desktop";
      "application/json" = "nvim-ghostty.desktop";
      "application/xml" = "nvim-ghostty.desktop";
      "application/xhtml+xml" = "nvim-ghostty.desktop";
      "application/javascript" = "nvim-ghostty.desktop";
      "application/typescript" = "nvim-ghostty.desktop";
      "application/x-python" = "nvim-ghostty.desktop";
      "application/x-ipynb+json" = "nvim-ghostty.desktop";
      "application/toml" = "nvim-ghostty.desktop";
      "application/x-npy" = "nvim-ghostty.desktop";

      # Terminal emulator
      "x-scheme-handler/terminal" = "com.mitchellh.ghostty.desktop";
    };
  };

  # SSH tunnel functions for SOCKS proxy via GNOME system proxy
  programs.zsh.initContent = ''
    # SSH tunnel functions for easy VPN-like functionality
    function tunnel-on() {
      if [[ -z "$1" ]]; then
        echo "Usage: tunnel-on <host>"
        return 1
      fi

      local host="$1"
      local port=1080  # Use port 1080 (standard SOCKS port)

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
      if [[ $? -eq 0 ]]; then
        echo "Tunnel established. Configuring system proxy..."

        # Configure GNOME system proxy settings
        gsettings set org.gnome.system.proxy mode 'manual'
        gsettings set org.gnome.system.proxy.socks host 'localhost'
        gsettings set org.gnome.system.proxy.socks port $port

        echo "✓ System proxy enabled (localhost:$port -> $host)"
      else
        echo "✗ Failed to establish tunnel to $host"
        return 1
      fi
    }

    function tunnel-off() {
      local port=1080
      echo "Disabling system proxy..."
      gsettings set org.gnome.system.proxy mode 'none'
      echo "✓ System proxy disabled"

      echo "Stopping SSH tunnels..."
      pkill -f "ssh -D $port"
      echo "✓ SSH tunnels stopped"
    }

    function tunnel-status() {
      local port=1080
      echo "=== GNOME System Proxy Status ==="
      echo "Mode: $(gsettings get org.gnome.system.proxy mode)"
      echo "SOCKS Host: $(gsettings get org.gnome.system.proxy.socks host)"
      echo "SOCKS Port: $(gsettings get org.gnome.system.proxy.socks port)"

      echo ""
      echo "=== Active SSH Tunnels ==="
      local tunnels=$(ps aux | grep -E "ssh -D $port" | grep -v grep)
      if [[ -n "$tunnels" ]]; then
        echo "$tunnels"
      else
        echo "No active SSH tunnels"
      fi
    }
  '';
}
