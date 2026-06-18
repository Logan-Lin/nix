{ config, pkgs, lib, ... }:

let
  fdIgnorePatterns = [
    "Documents/app-state"
    "Library"
  ];
  fdExcludes = lib.concatMapStrings (p: "-E ${lib.escapeShellArg p} ") fdIgnorePatterns;
in
{
  programs.zsh = {
    enable = true;
    enableVteIntegration = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
      TERM = "xterm-256color";
    };
    
    shellAliases = {
      ls = "eza";
      ll = "eza -l --icons --group --git";
      la = "eza -la --icons --group --git";
      lt = "eza --tree --icons";

      hms = "home-manager switch --flake ~/.config/nix#$(whoami)@$(hostname)";
      nd = "nix develop";
      ndr = "nix develop ./runtime";
    };
    
    initContent = ''
      bindkey -e
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^G' edit-command-line

      # Function to cd to directory containing a file selected with fzf
      function cdf() {
        local search_dir="''${1:-~}"
        local target
        target=$(echo "" | fzf --bind "change:reload:fd --follow ${fdExcludes}{q} ''$search_dir 2>/dev/null || true" --header="Type to search, Enter to cd" --preview '([[ -d {} ]] && ls -la {}) || ([[ -f {} ]] && head -20 {})' --height 40% --ansi)
        if [[ -n "$target" ]]; then
          [[ -d "$target" ]] && cd "$target" || cd "$(dirname "$target")"
        fi
      }

      # Function to print path of file/directory selected with fzf
      function pwdf() {
        local search_dir="''${1:-~}"
        local target
        target=$(echo "" | fzf --bind "change:reload:fd --follow ${fdExcludes}{q} ''$search_dir 2>/dev/null || true" --header="Type to search, Enter to print path" --preview '([[ -d {} ]] && ls -la {}) || ([[ -f {} ]] && head -20 {})' --height 40% --ansi)
        if [[ -n "$target" ]]; then
          echo "$target"
        fi
      }

      # Function to show current directory in file manager
      function fm() {
        local current_dir="$(pwd)"
        ${if pkgs.stdenv.isDarwin then
          "open -R \"$current_dir\""
        else
          "thunar \"$current_dir\" &"}
      }

    '';
  };
  
  # Essential packages for enhanced zsh experience
  home.packages = with pkgs; [
    fzf
    fd
    ripgrep
    bat
    jq
  ];
  
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    icons = "auto";
    git = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;

      format = lib.concatStrings [
        "$directory"
        "$git_branch"
        "$git_status"
        "$jobs"
        "$python"
        "$nix_shell"
        "$username"
        "$hostname"
        "$line_break"
        "$character"
      ];

      character = {
        success_symbol = "[❯](bold #b8bb26)";
        error_symbol = "[❯](bold #fb4934)";
      };

      directory = {
        style = "bold #83a598";
        truncation_length = 5;
        truncate_to_repo = true;
        fish_style_pwd_dir_length = 1;
        read_only = " ";
      };

      git_branch = {
        style = "#d3869b";
        symbol = " ";
        format = "[$symbol$branch(:$remote_branch)]($style) ";
      };

      git_status = {
        style = "#d3869b";
        modified = "!";
        staged = "+";
        untracked = "?";
        ahead = "⇡";
        behind = "⇣";
        diverged = "⇕";
        deleted = "󰩹";
      };

      jobs.style = "#fb4934";

      python = {
        style = "#fe8019";
        format = "[ $virtualenv]($style) ";
        detect_extensions = [];
        detect_files = [];
        detect_folders = [];
      };

      nix_shell = {
        style = "#83a598";
        symbol = " ";
        format = "[$symbol$state]($style) ";
      };

      username = {
        show_always = false;
        style_user = "#fabd2f";
        format = "[$user]($style) ";
      };

      hostname = {
        ssh_only = true;
        style = "#fabd2f";
        ssh_symbol = " ";
        format = "[$ssh_symbol$hostname]($style) ";
      };
    };
  };
}
