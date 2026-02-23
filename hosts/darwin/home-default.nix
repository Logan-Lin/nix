{ config, lib, pkgs, nixvim, firefox-addons, ... }:

{
  imports = [
    nixvim.homeModules.nixvim
    ../../modules/nvim.nix
    ../../modules/tmux.nix
    ../../modules/zsh.nix
    ../../modules/ssh.nix
    ../../modules/git/home.nix
    ../../modules/git/lazygit.nix
    ../../modules/btop.nix
    ../../modules/firefox/home.nix
    ../../modules/ghostty.nix
    ../../modules/syncthing.nix
    ../../modules/claude-code.nix
    ../../modules/media/tool.nix
    ../../modules/font/home.nix
  ];

  syncthing-custom.folders = {
    Credentials.enable = true;
    Documents.enable = true;
    Archive.enable = true;
  };

  nixpkgs.config.allowUnfree = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = true;
  };

  programs.firefox-custom = {
    enable = true;
    package = null;
  };

  programs.ghostty-custom = {
    enable = true;
    package = null;
    windowMode = "windowed";
  };

  home.username = "yanlin";
  home.homeDirectory = "/Users/yanlin";
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.zsh.shellAliases = {
      oss = "sudo darwin-rebuild switch --flake ~/.config/nix#$(hostname)";
  };

  home.packages = with pkgs; [
    texlive.combined.scheme-full
    httpie
    gnumake
    bind
    inetutils
    netcat-gnu
    curl
    wget
    bandwhich
    ncdu
    fastfetch
    coreutils
    duti
    rsync
  ];

  launchd.agents.maccy = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/Maccy.app/Contents/MacOS/Maccy" ];
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

  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [ "/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };

  home.activation.setFileAssociations = config.lib.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .txt all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .md all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .markdown all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .nix all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .sh all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .bash all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .zsh all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .fish all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .py all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .js all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .ts all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .jsx all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .tsx all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .json all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .yaml all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .yml all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .toml all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .xml all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .css all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .log all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .csv all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .conf all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .config all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .ini all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .env all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .c all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .cpp all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .h all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .hpp all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .rs all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .go all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .java all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .rb all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .php all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .lua all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .vim all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .tex all
    run ${pkgs.duti}/bin/duti -s com.apple.TextEdit .bib all
    run ${pkgs.duti}/bin/duti -s com.apple.Preview .pdf all
    run ${pkgs.duti}/bin/duti -s org.inkscape.Inkscape .svg all
    run ${pkgs.duti}/bin/duti -s com.jgraph.drawio.desktop .drawio all
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
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .mp3 all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .m4a all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .flac all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .wav all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .aac all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .ogg all
    run ${pkgs.duti}/bin/duti -s com.colliderli.iina .opus all
  '';

  home.file.".config/linearmouse/linearmouse.json".text = builtins.toJSON {
    schemes = [{
      "if".device.category = "mouse";
      scrolling.distance = "64px";
      scrolling.reverse = {
        vertical = true;
        horizontal = false;
      };
      pointer = {
        acceleration = 0;
        speed = 0.8;
      };
      buttons.mappings = [{
        button = 2;
        action = "smartZoom";
      }];
    }];
  };

  home.file.".aerospace.toml".text = ''
    [workspace-to-monitor-force-assignment]
    10 = 'secondary'

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
