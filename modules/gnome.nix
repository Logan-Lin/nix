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
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "firefox.desktop"
        "obsidian.desktop"
        "com.mitchellh.ghostty.desktop"
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
  };

  # Configure cursor theme system-wide
  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Configure GTK icon theme
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

  # GNOME Shell extensions
  home.packages = with pkgs; [
    gnomeExtensions.hide-top-bar
    gnomeExtensions.pano
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
    MimeType=text/plain;text/markdown;text/x-nix;text/x-shellscript;application/x-yaml;application/json;
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

      # Text and code files
      "text/plain" = "nvim-ghostty.desktop";
      "text/markdown" = "nvim-ghostty.desktop";
      "text/x-nix" = "nvim-ghostty.desktop";
      "text/x-shellscript" = "nvim-ghostty.desktop";
      "application/x-yaml" = "nvim-ghostty.desktop";
      "application/json" = "nvim-ghostty.desktop";

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
