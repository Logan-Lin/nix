# Tmux configuration that sets a Gruvbox status line, vi style pane navigation and copy mode, and automatic session save and restore through the resurrect and continuum plugins.
# Adds the sesh session manager with a zsh alias and a prefix popup to switch sessions through fzf.

{ pkgs, ... }:

{
  home.packages = [ pkgs.sesh ];

  programs.zsh.shellAliases.ts = "sesh connect $(sesh list --icons | fzf --reverse --border --ansi)";

  programs.tmux = {
    enable = true;
    shortcut = "a";
    baseIndex = 1;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";

    plugins = [
      {
        # Resurrect records process commands even when process restoration is disabled.
        plugin = pkgs.tmuxPlugins.resurrect.overrideAttrs (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            substituteInPlace scripts/save.sh \
              --replace-fail \
                'full_command="$(pane_full_command $pane_pid)"' \
                'full_command=""; pane_command=""'
          '';
        });
        # Restore the tmux layout without processes.
        extraConfig = "set -g @resurrect-processes 'false'";
      }
      {
        plugin = pkgs.tmuxPlugins.continuum;
        # Save the session automatically every hour.
        extraConfig = "set -g @continuum-save-interval '60'";
      }
    ];

    extraConfig = ''
      set -g default-terminal "xterm-256color"
      # Enable true color, italics, and cursor shape changes for the xterm-256color terminal.
      set -ga terminal-overrides ",xterm-256color:Tc,xterm-256color:sitm=\\E[3m:ritm=\\E[23m,xterm-256color:Ss=\\E[%p1%d q:Se=\\E[2 q"
      set -g set-clipboard on

      set -g status-style 'bg=#3c3836,fg=#ebdbb2'
      set -g status-left-style 'bg=#a89984,fg=#282828,bold'
      set -g status-right-style 'bg=#a89984,fg=#282828,bold'
      set -g window-status-style 'bg=#3c3836,fg=#a89984'
      set -g window-status-current-style 'bg=#1d2021,fg=#ebdbb2,bold'
      set -g pane-border-style 'fg=#3c3836'
      set -g pane-active-border-style 'fg=#fabd2f'
      set -g message-style 'bg=#fabd2f,fg=#282828,fill=#fabd2f'
      set -g message-command-style 'bg=#fabd2f,fg=#282828,fill=#fabd2f'
      set -g mode-style 'bg=#504945'
      set -g copy-mode-match-style 'bg=#fabd2f,fg=#282828'
      set -g copy-mode-current-match-style 'bg=#fe8019,fg=#282828'

      set -g status-left-length 50
      set -g status-right-length 50
      set -g status-left '#{?client_prefix,#[bg=#fe8019],#[bg=#a89984]}#[fg=#282828] #S '
      set -g status-right '#{?pane_in_mode,#[bg=#fe8019]#[fg=#282828] COPY ,}#{?window_zoomed_flag,#[bg=#fe8019]#[fg=#282828] ZOOM ,}#{?SSH_CONNECTION,#[bg=#fabd2f],#[bg=#a89984]}#[fg=#282828] #H '
      set -g window-status-format ' #I:#W '
      set -g window-status-current-format ' #I:#W '
      set -g window-status-separator ""

      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind H swap-pane -t '{left-of}' \; select-pane -t '{left-of}'
      bind J swap-pane -t '{down-of}' \; select-pane -t '{down-of}'
      bind K swap-pane -t '{up-of}' \; select-pane -t '{up-of}'
      bind L swap-pane -t '{right-of}' \; select-pane -t '{right-of}'
      bind -r Left resize-pane -L 5
      bind -r Down resize-pane -D 5
      bind -r Up resize-pane -U 5
      bind -r Right resize-pane -R 5

      bind ^A send-prefix
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Config reloaded!"
      bind s display-popup -w 76 -h 75% -B -E "sesh connect $(sesh list --icons | fzf --reverse --border --ansi)"
      unbind w
      unbind q
      bind Tab display-panes
      bind c new-window -c "#{pane_current_path}"
      bind-key x kill-pane
      bind-key & confirm-before -p "kill-window? (y/n)" kill-window
      bind-key * confirm-before -p "kill-session? (y/n)" kill-session
      bind-key -n C-S-Left swap-window -t -1\; select-window -t -1
      bind-key -n C-S-Right swap-window -t +1\; select-window -t +1

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      set-option -g allow-rename off
      set -g automatic-rename-format ""
      set -g history-limit 10000
      set -g display-time 2000
      set -g display-panes-time 3000
      set -s extended-keys on
      set -as terminal-features 'xterm*:extkeys'
      set -as terminal-features '*:clipboard'
      set -s escape-time 0
      set -g renumber-windows on
      set -g detach-on-destroy off
    '';
  };
}
