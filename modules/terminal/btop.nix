{ pkgs, lib, ... }:

{
  programs.btop = {
    enable = true;

    settings = {
      color_theme = "gruvbox_dark";
      theme_background = false;
      truecolor = true;
      rounded_corners = true;
      graph_symbol = "braille";

      vim_keys = true;

      update_ms = 1000;
      background_update = true;

      cpu_single_graph = false;
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";
      cpu_invert_lower = true;
      show_uptime = true;
      show_cpu_freq = true;
      check_temp = true;
      show_coretemp = true;
      temp_scale = "celsius";
      cpu_sensor = "Auto";

      proc_sorting = "cpu lazy";
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      show_init = false;

      mem_graphs = true;
      show_swap = true;
      swap_disk = true;

      show_disks = true;
      use_fstab = false;
      disks_filter = "";

      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = false;
      net_iface = "";

      show_battery = true;

      show_gpu_info = "Auto";
      nvml_measure_pcie_speeds = false;
      gpu_mirror_graph = true;

      shown_boxes = "cpu mem net proc gpu";
      presets = "cpu:1:default,proc:0:default cpu:0:default,mem:0:default,net:0:default cpu:0:block,net:0:tty";

      draw_clock = "%X";

      force_tty = false;
      custom_cpu_name = "";
    };
  };
}
