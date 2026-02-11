{ config, pkgs, nixvim, firefox-addons, ... }:

{
  imports = [
    nixvim.homeModules.nixvim
    ../../modules/nvim.nix
    ../../modules/tmux.nix
    ../../modules/zsh.nix
    ../../modules/ssh.nix
    ../../modules/git.nix
    ../../modules/lazygit.nix
    ../../modules/rsync.nix
    ../../modules/btop.nix
    ../../modules/firefox.nix
    ../../modules/ghostty.nix
    ../../modules/syncthing.nix
    ../../modules/claude-code.nix
    ../../modules/tex.nix
    ../../modules/media/tool.nix
    ../../modules/fonts.nix
    ../../modules/aerospace.nix
    ../../modules/peripheral/home.nix
    ../../modules/env.nix
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
    delta
    fastfetch
    coreutils      # GNU core utilities (base64, etc.)
    duti           # Set default applications for file types (macOS)
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

  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.tailscale = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  launchd.agents.linearmouse = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/LinearMouse.app/Contents/MacOS/LinearMouse" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  # File associations configuration (macOS equivalent of xdg.mimeApps)
  # Uses duti to set default applications for file types via Launch Services
  home.activation.setFileAssociations = config.lib.dag.entryAfter ["writeBoundary"] ''
    # Text and code files - open with TextMate
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .txt all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .md all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .markdown all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .nix all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .sh all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .bash all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .zsh all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .fish all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .py all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .js all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .ts all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .jsx all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .tsx all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .json all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .yaml all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .yml all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .toml all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .xml all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .css all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .log all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .csv all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .conf all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .config all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .ini all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .env all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .c all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .cpp all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .h all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .hpp all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .rs all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .go all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .java all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .rb all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .php all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .lua all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .vim all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .tex all
    run ${pkgs.duti}/bin/duti -s com.coteditor.CotEditor .bib all

    # Documents
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .pdf all

    # Diagrams - Draw.io
    run ${pkgs.duti}/bin/duti -s com.jgraph.drawio.desktop .drawio all

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
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .ico all

    # SVG - Inkscape
    run ${pkgs.duti}/bin/duti -s org.inkscape.Inkscape .svg all

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
