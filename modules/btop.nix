{ pkgs, ... }:

{
  programs.btop = {
    enable = true;
    
    settings = {
      # Theme and Visual Settings (Gruvbox Dark to match nvim/tmux)
      color_theme = "gruvbox_dark";
      theme_background = false;     # Transparent background
      truecolor = true;            # 24-bit color support
      rounded_corners = true;      # Modern rounded appearance
      graph_symbol = "braille";    # High-resolution graph symbols
      
      # Vim-style Navigation
      vim_keys = true;             # Enable h,j,k,l,g,G navigation
      
      # Performance and Update Settings
      update_ms = 1000;            # Faster updates (1 second)
      background_update = true;    # Continue updating when not focused
      
      # CPU Display Settings
      cpu_single_graph = false;    # Show per-core graphs
      cpu_graph_upper = "total";   # Upper graph shows total usage
      cpu_graph_lower = "total";   # Lower graph shows total usage
      cpu_invert_lower = true;     # Invert lower graph for better visualization
      show_uptime = true;          # Display system uptime
      show_cpu_freq = true;        # Show CPU frequency
      check_temp = true;           # Monitor CPU temperature
      show_coretemp = true;        # Display core temperatures
      temp_scale = "celsius";      # Use Celsius for temperature
      cpu_sensor = "Auto";         # Auto-detect temperature sensors
      
      # Process Display Settings
      proc_sorting = "cpu lazy";   # Sort by CPU usage, lazy update
      proc_tree = true;            # Show process hierarchy
      proc_colors = true;          # Colorize process list
      proc_gradient = true;        # Use gradient colors for processes
      proc_per_core = false;       # Don't show per-core process usage
      proc_mem_bytes = true;       # Show memory in bytes
      show_init = false;           # Hide init processes
      
      # Memory Settings
      mem_graphs = true;           # Show memory graphs
      show_swap = true;            # Display swap usage
      swap_disk = true;            # Show swap as disk usage
      
      # Disk Settings
      show_disks = true;           # Display disk usage
      use_fstab = false;          # Don't use fstab for disk detection
      disks_filter = "";          # No disk filtering
      
      # Network Settings
      net_download = 100;          # Network download scale (Mbps)
      net_upload = 100;           # Network upload scale (Mbps)
      net_auto = true;            # Auto-scale network graphs
      net_sync = false;           # Don't sync download/upload scales
      net_iface = "";             # Auto-detect network interface
      
      # Battery Settings (MacBook Air)
      show_battery = true;         # Show battery status
      
      # Layout Settings
      shown_boxes = "cpu mem net proc";  # Show all main boxes
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";
      
      # Clock Display
      draw_clock = "%X";           # Display time in HH:MM:SS format
      
      # Miscellaneous
      force_tty = false;           # Don't force TTY mode
      custom_cpu_name = "";        # Use detected CPU name
    };
  };
}
