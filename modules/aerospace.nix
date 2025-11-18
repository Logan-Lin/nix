{ config, pkgs, ... }:

{
  # Install aerospace package
  home.packages = [ pkgs.aerospace ];

  # AeroSpace configuration following Hyprland keybindings
  xdg.configFile."aerospace/aerospace.toml".text = ''
    # Reference: https://github.com/nikitabobko/AeroSpace/blob/main/docs/config-reference.md

    # Behavior settings
    after-login-command = []
    after-startup-command = []

    # Auto-start managed by launchd agent (see bottom of this file)
    start-at-login = false

    # Normalizations
    enable-normalization-flatten-containers = true
    enable-normalization-opposite-orientation-for-nested-containers = true

    # Gaps (matching Hyprland: no gaps)
    accordion-padding = 0

    # Default root container layout
    default-root-container-layout = 'tiles'

    # Default container orientation
    default-root-container-orientation = 'auto'

    # Mouse follows focus
    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

    # Workspace to monitor assignment (macOS native displays)
    [workspace-to-monitor-force-assignment]
    1 = 'main'
    2 = 'main'
    3 = 'main'
    4 = 'main'
    5 = 'main'
    6 = 'main'
    7 = 'main'
    8 = 'main'
    9 = 'main'

    # Mode definitions
    [mode.main.binding]

    # Core window management (matching Hyprland: Super+Q/F/V)
    # Using alt instead of cmd to avoid macOS conflicts
    alt-q = 'close'
    alt-f = 'fullscreen'
    alt-shift-space = 'layout floating tiling' # Toggle float/tile

    # Application launcher (matching Hyprland: Super+Return for terminal)
    alt-enter = 'exec-and-forget open -n -a Ghostty'

    # Window focus navigation (vim-style: alt+h/j/k/l)
    alt-h = 'focus left'
    alt-j = 'focus down'
    alt-k = 'focus up'
    alt-l = 'focus right'

    # Window moving/swapping (matching Hyprland: Ctrl+hjkl)
    alt-ctrl-h = 'move left'
    alt-ctrl-j = 'move down'
    alt-ctrl-k = 'move up'
    alt-ctrl-l = 'move right'

    # Window resizing (matching Hyprland: Shift+hjkl)
    alt-shift-h = 'resize width -50'
    alt-shift-j = 'resize height +50'
    alt-shift-k = 'resize height -50'
    alt-shift-l = 'resize width +50'

    # Workspace navigation (1-9, matching Hyprland exactly)
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # Move window to workspace (Shift+1-9, matching Hyprland)
    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'

    # Layout management
    alt-slash = 'layout tiles horizontal vertical'
    alt-comma = 'layout accordion horizontal vertical'

    # Service mode for aerospace-specific commands
    alt-shift-semicolon = 'mode service'

    # See: https://nikitabobko.github.io/AeroSpace/commands#mode
    [mode.service.binding]
    esc = ['reload-config', 'mode main']
    r = ['flatten-workspace-tree', 'mode main']
    f = ['layout floating tiling', 'mode main']
    backspace = ['close-all-windows-but-current', 'mode main']

    alt-shift-h = ['join-with left', 'mode main']
    alt-shift-j = ['join-with down', 'mode main']
    alt-shift-k = ['join-with up', 'mode main']
    alt-shift-l = ['join-with right', 'mode main']
  '';

  # Setup launchd agent for auto-start
  launchd.agents.aerospace = {
    enable = true;
    config = {
      ProgramArguments = [ "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ];
      RunAtLoad = true;
      KeepAlive = false;
    };
  };
}
