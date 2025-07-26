{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;   # Start windows and panes at 1, not 0
    mouse = true;    # Enable mouse support
    keyMode = "vi";  # Use vi key bindings in copy mode
    terminal = "screen-256color";  # Force 256 color support
    
    extraConfig = ''
      # Terminal settings
      set -g default-terminal "screen-256color"
      set -ga terminal-overrides ",xterm-256color:Tc"
      
      # Gruvbox Dark Theme (Truecolor)
      # Status bar colors
      set -g status-style 'bg=#282828,fg=#ebdbb2'
      set -g status-left-style 'bg=#a89984,fg=#282828'
      set -g status-right-style 'bg=#a89984,fg=#282828'
      
      # Window status colors
      set -g window-status-style 'bg=#3c3836,fg=#a89984'
      set -g window-status-current-style 'bg=#fabd2f,fg=#282828'
      set -g window-status-activity-style 'bg=#fb4934,fg=#282828'
      
      # Pane border colors
      set -g pane-border-style 'fg=#3c3836'
      set -g pane-active-border-style 'fg=#fabd2f'
      
      # Message colors
      set -g message-style 'bg=#fabd2f,fg=#282828'
      set -g message-command-style 'bg=#fabd2f,fg=#282828'
      
      # Status bar content
      set -g status-left-length 40
      set -g status-right-length 20
      set -g status-left ' #S '
      set -g status-right '#{?client_prefix,#[reverse]<Prefix>#[noreverse] ,}'
      
      # Window status format
      set -g window-status-format ' #I:#W '
      set -g window-status-current-format ' #I:#W '
      
      # Better key bindings for splitting panes
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %
      
      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      
      # Vim-like pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      
      # Quick pane cycling
      unbind o
      bind ^A select-pane -t :.+
      
      # Reload config file
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      
      # Better copy mode
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle
      
      # New window with current path
      bind c new-window -c "#{pane_current_path}"
      
      # Don't rename windows automatically
      set-option -g allow-rename off
      
      # Increase scrollback buffer size
      set -g history-limit 10000
      
      # Display messages for longer
      set -g display-time 2000
      
      # Faster command sequences
      set -s escape-time 0
      
      # Activity monitoring
      setw -g monitor-activity on
      set -g visual-activity off
      
      # Automatically renumber windows
      set -g renumber-windows on
    '';
  };
}
