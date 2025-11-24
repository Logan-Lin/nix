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
    ../../modules/linearmouse.nix
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
    imagemagick
    git-credential-oauth
    zoxide
    delta
    fastfetch
    coreutils      # GNU core utilities (base64, etc.)
    tree
    bzip2
    unzip
    duti           # Set default applications for file types (macOS)

    # Development and build tools
    python312
    uv
    lazysql
    sqlite
  ];

  # Startup applications via launchd agents
  launchd.agents.snipaste = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Snipaste.app/Contents/MacOS/Snipaste" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.maccy = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Maccy.app/Contents/MacOS/Maccy" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.hidden-bar = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Hidden Bar.app/Contents/MacOS/Hidden Bar" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.rectangle = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Rectangle.app/Contents/MacOS/Rectangle" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # File associations configuration (macOS equivalent of xdg.mimeApps)
  # Uses duti to set default applications for file types via Launch Services
  home.activation.setFileAssociations = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Text and code files - open with TextMate
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .txt all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .md all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .markdown all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .nix all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .sh all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .bash all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .zsh all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .fish all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .py all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .js all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .ts all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .jsx all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .tsx all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .json all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .yaml all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .yml all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .toml all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .xml all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .css all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .log all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .csv all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .conf all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .config all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .ini all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .env all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .c all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .cpp all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .h all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .hpp all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .rs all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .go all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .java all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .rb all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .php all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .lua all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .vim all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .tex all
    run ${pkgs.duti}/bin/duti -s com.macromates.TextMate .bib all

    # Documents - PDF with Preview
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .pdf all

    # Images - Preview
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .png all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .jpg all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .jpeg all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .gif all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .bmp all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .tiff all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .tif all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .webp all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .heic all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .heif all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .svg all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .ico all

    # Videos - IINA
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mp4 all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mkv all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .avi all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mov all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .wmv all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .flv all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .webm all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .m4v all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mpg all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mpeg all

    # Audio - IINA
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mp3 all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .m4a all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .flac all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .wav all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .aac all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .ogg all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .opus all
  '';
}
