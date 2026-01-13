{ pkgs, ... }:

let
  continuumSaveScript = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh";
in
{
  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;   # Start windows and panes at 1, not 0
    mouse = true;    # Enable mouse support
    keyMode = "vi";  # Use vi key bindings in copy mode
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes 'nvim lazygit claude ssh'
          set -g @resurrect-hook-post-save-all 'target=$(readlink -f ~/.tmux/resurrect/last); perl -i -pe "s|/nix/store/[^/]*/bin/nvim --cmd .*|nvim|g" "$target"'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
    
    extraConfig = ''
      # Terminal settings for true color and italic support
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",xterm-256color:Tc,xterm-256color:sitm=\\E[3m:ritm=\\E[23m"

      # Enable OSC-52 clipboard integration (works with Ghostty)
      set -g set-clipboard on
      
      # Gruvbox Dark Theme (Truecolor)
      # Status bar colors
      set -g status-style 'bg=#282828,fg=#ebdbb2'
      set -g status-left-style 'bg=#a89984,fg=#282828'
      set -g status-right-style 'bg=#a89984,fg=#282828'
      
      # Window status colors
      set -g window-status-style 'bg=#3c3836,fg=#a89984'
      set -g window-status-current-style 'bg=#fabd2f,fg=#282828'

      # Pane border colors
      set -g pane-border-style 'fg=#3c3836'
      set -g pane-active-border-style 'fg=#fabd2f'
      
      # Message colors
      set -g message-style 'bg=#fabd2f,fg=#282828'
      set -g message-command-style 'bg=#fabd2f,fg=#282828'
      
      # Copy mode colors
      set -g mode-style 'bg=#fabd2f,fg=#282828'
      set -g copy-mode-match-style 'bg=#fabd2f,fg=#282828'
      set -g copy-mode-current-match-style 'bg=#fb4934,fg=#282828'
      
      # Status bar content
      set -g status-left-length 40
      set -g status-right-length 50
      set -g status-left '#{?client_prefix,#[bg=#fb4934],#[bg=#a89984]}#[fg=#282828] #S #[bg=#282828] '
      set -g status-right '#(${continuumSaveScript})#[bg=#282828]#[fg=#ebdbb2] #{=20:#{b:pane_current_path}} #{?SSH_CLIENT,#[bg=#fabd2f],#[bg=#a89984]}#[fg=#282828]#{?pane_in_mode, [COPY],} #H | %H:%M '
      
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
      
      # Enable nested session control
      # Ctrl-a Ctrl-a sends prefix to inner tmux session
      bind ^A send-prefix
      
      # Reload config file
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      
      # Better copy mode with OSC-52 clipboard
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe
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
      
      # Automatically renumber windows
      set -g renumber-windows on
      
      # Quick window movement
      bind-key -n C-S-Left swap-window -t -1\; select-window -t -1
      bind-key -n C-S-Right swap-window -t +1\; select-window -t +1
    '';
  };
}
