{ config, pkgs, nixvim, claude-code, firefox-addons, ... }:

{
  imports = [
    nixvim.homeModules.nixvim
    ../../modules/nvim.nix
    ../../modules/tmux.nix
    ../../modules/zsh.nix
    ../../modules/ssh.nix
    ../../modules/git.nix
    ../../modules/lazygit.nix
    ../../modules/papis.nix
    ../../modules/termscp.nix
    ../../modules/rsync.nix
    ../../modules/btop.nix
    ../../modules/firefox.nix
    ../../modules/ghostty.nix
    ../../modules/syncthing.nix
    ../../modules/dictionary.nix
    ../../modules/yt-dlp.nix
    ../../modules/claude-code.nix
    ../../modules/tex.nix
    ../../modules/fonts.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Firefox configuration
  programs.firefox-custom = {
    enable = true;
    package = null;  # Use system Firefox on Darwin
  };

  # Ghostty configuration
  programs.ghostty-custom = {
    enable = true;
    package = null;  # Use Homebrew-installed Ghostty on Darwin
    windowMode = "windowed";
    windowWidth = 999;
    windowHeight = 999;
  };

  home.username = "yanlin";
  home.homeDirectory = "/Users/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  # darwin-specific alias
  programs.zsh.shellAliases = {
      oss = "sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)";

      preview = "open -a Preview";
      slide = "open -a SlidePilot";

      # Network monitoring aliases
      bw = "sudo bandwhich";
      bw-raw = "sudo bandwhich --raw";
      bw-dns = "sudo bandwhich --show-dns";
  };

  # Darwin-specific zsh functions
  programs.zsh.initContent = ''
    # Function to search and open all macOS applications
    function app() {
      local app_path
      local file_to_open="$1"

      app_path=$( (find -L /Applications -name "*.app" -maxdepth 2 2>/dev/null; \
                   find -L ~/Applications -name "*.app" -maxdepth 3 2>/dev/null; \
                   find /System/Applications -name "*.app" -maxdepth 2 2>/dev/null; \
                   find /System/Applications/Utilities -name "*.app" -maxdepth 1 2>/dev/null) |
        sort | uniq |
        fzf --header="Select app to open''${file_to_open:+ file: $file_to_open}" \
            --preview 'basename {} .app' \
            --preview-window=up:1 \
            --height=40%)

      if [[ -n "$app_path" ]]; then
        if [[ -n "$file_to_open" ]]; then
          open -a "$app_path" "$file_to_open"
        else
          open "$app_path"
        fi
      fi
    }

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

        # Configure system proxy
        networksetup -setsocksfirewallproxy "Wi-Fi" localhost $port
        networksetup -setsocksfirewallproxystate "Wi-Fi" on

        echo "✓ System proxy enabled on Wi-Fi (localhost:$port -> $host)"
      else
        echo "✗ Failed to establish tunnel to $host"
        return 1
      fi
    }

    function tunnel-off() {
      local port=1080
      echo "Disabling system proxy..."
      networksetup -setsocksfirewallproxystate "Wi-Fi" off
      echo "✓ System proxy disabled"

      echo "Stopping SSH tunnels..."
      pkill -f "ssh -D $port"
      echo "✓ SSH tunnels stopped"
    }

    function tunnel-status() {
      local port=1080
      echo "=== System Proxy Status ==="
      networksetup -getsocksfirewallproxy "Wi-Fi" | grep -E "Enabled|Server|Port"

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

  home.packages = with pkgs; [
    # Network and file transfer
    lftp
    httpie
    openssh
    gnumake

    # Network diagnostic tools
    bind           # DNS utilities (dig, nslookup, mdig)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility
    curl           # HTTP client
    wget           # Web downloader
    bandwhich      # Terminal bandwidth utilization tool

    # Command-line utilities
    ncdu
    git-credential-oauth
    zoxide
    delta
    fastfetch
    coreutils      # GNU core utilities (base64, etc.)

    # macOS-specific GUI applications
    maccy          # Clipboard manager (macOS-only)
    iina           # Media player (macOS-optimized)
    hidden-bar     # Menu bar organizer (macOS-only)

    # Development and build tools
    python312
    uv
    lazysql
    sqlite
  ];
}
