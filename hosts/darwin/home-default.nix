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
    ../../modules/btop.nix
    ../../modules/firefox/home.nix
    ../../modules/ghostty.nix
    ../../modules/syncthing.nix
    ../../modules/claude-code.nix
    ../../modules/media/tool.nix
    ../../modules/font/home.nix
  ];

  nixpkgs.config.allowUnfree = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

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
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
    gnumake
    bind           # DNS utilities (dig, nslookup, mdig)
    inetutils      # Network utilities (telnet)
    netcat-gnu     # Network connection utility
    curl           # HTTP client
    wget           # Web downloader
    bandwhich      # Terminal bandwidth utilization tool
    ncdu
    delta
    fastfetch
    coreutils      # GNU core utilities (base64, etc.)
    duti           # Set default applications for file types (macOS)
    rsync
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

  home.file.".config/linearmouse/linearmouse.json".text = builtins.toJSON {
    "$schema" = "https://app.linearmouse.org/schema/0.10.0";
    schemes = [{
      "if" = {
        device.category = "mouse";
      };
      scrolling.reverse.vertical = true;
      pointer = {
        acceleration = 0;
        speed = 0.6;
      };
    }];
  };

  home.file.".aerospace.toml".text = ''
    # Make all new windows floating by default
    [[on-window-detected]]
    run = ['layout floating']

    [mode.main.binding]
    alt-enter = 'layout floating tiling'
    alt-f = 'fullscreen'
    alt-q = 'close'

    # Window focus (vim-style)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Move windows
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # Resize
    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'

    # Workspaces
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'
    alt-0 = 'workspace 10'

    # Focus monitor
    alt-comma = 'focus-monitor prev'
    alt-period = 'focus-monitor next'

    # Move window to monitor
    alt-shift-comma = 'move-node-to-monitor prev'
    alt-shift-period = 'move-node-to-monitor next'

    # Move window to workspace
    alt-shift-1 = ['move-node-to-workspace 1', 'workspace 1']
    alt-shift-2 = ['move-node-to-workspace 2', 'workspace 2']
    alt-shift-3 = ['move-node-to-workspace 3', 'workspace 3']
    alt-shift-4 = ['move-node-to-workspace 4', 'workspace 4']
    alt-shift-5 = ['move-node-to-workspace 5', 'workspace 5']
    alt-shift-6 = ['move-node-to-workspace 6', 'workspace 6']
    alt-shift-7 = ['move-node-to-workspace 7', 'workspace 7']
    alt-shift-8 = ['move-node-to-workspace 8', 'workspace 8']
    alt-shift-9 = ['move-node-to-workspace 9', 'workspace 9']
    alt-shift-0 = ['move-node-to-workspace 10', 'workspace 10']
  '';

}
