{ pkgs, ... }:

let
  continuumSaveScript = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh";
in
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
          set -g @continuum-save-interval '60'
        '';
      }
    ];

    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",xterm-256color:Tc,xterm-256color:sitm=\\E[3m:ritm=\\E[23m"
      set -g set-clipboard on

      set -g status-style 'bg=#282828,fg=#ebdbb2'
      set -g status-left-style 'bg=#a89984,fg=#282828'
      set -g status-right-style 'bg=#a89984,fg=#282828'
      set -g window-status-style 'bg=#3c3836,fg=#a89984'
      set -g window-status-current-style 'bg=#fabd2f,fg=#282828'
      set -g pane-border-style 'fg=#3c3836'
      set -g pane-active-border-style 'fg=#fabd2f'
      set -g message-style 'bg=#fabd2f,fg=#282828'
      set -g message-command-style 'bg=#fabd2f,fg=#282828'
      set -g mode-style 'bg=#fabd2f,fg=#282828'
      set -g copy-mode-match-style 'bg=#fabd2f,fg=#282828'
      set -g copy-mode-current-match-style 'bg=#fb4934,fg=#282828'

      set -g status-left-length 40
      set -g status-right-length 50
      set -g status-left '#{?client_prefix,#[bg=#fb4934],#[bg=#a89984]}#[fg=#282828] #S #[bg=#282828] '
      set -g status-right '#(${continuumSaveScript})#[bg=#282828]#[fg=#ebdbb2] #{=20:#{b:pane_current_path}} #{?SSH_CLIENT,#[bg=#fabd2f],#[bg=#a89984]}#[fg=#282828]#{?pane_in_mode, [COPY],}#{?window_zoomed_flag, [Z],} #H | %H:%M '
      set -g window-status-format ' #I:#W '
      set -g window-status-current-format ' #I:#W '

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
      bind c new-window -c "#{pane_current_path}"
      bind-key x kill-pane
      bind-key & confirm-before -p "kill-window? (y/n)" kill-window
      bind-key * confirm-before -p "kill-session? (y/n)" kill-session
      bind-key C-S-Left swap-window -t -1\; select-window -t -1
      bind-key C-S-Right swap-window -t +1\; select-window -t +1

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-pipe
      bind-key -T copy-mode-vi r send-keys -X rectangle-toggle

      set-option -g allow-rename off
      set -g history-limit 10000
      set -g display-time 2000
      set -g display-panes-time 3000
      set -s escape-time 0
      set -g renumber-windows on
      set -g detach-on-destroy off
    '';
  };
}
