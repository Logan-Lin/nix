# Interactive zsh configuration for home-manager.
# Enables completion, autosuggestions, and syntax highlighting, adds shell functions that search and open files through fzf, and sets a Gruvbox themed starship prompt.

{ config, pkgs, lib, ... }:

let
  # Build fd exclude flags shared by the fzf file search functions.
  # The macOS home Library tree is large and slow to walk, so keep it out of the results.
  fdIgnorePatterns = [
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
      hms = "home-manager switch --flake ~/.config/nix#$(whoami)@$(hostname)";
      nd = "nix develop";
      ndr = "nix develop ./runtime";
    };
    
    initContent = ''
      bindkey -e
      autoload -Uz edit-command-line
      zle -N edit-command-line
      bindkey '^G' edit-command-line

      # Live file search through fzf.
      # Seeding fzf with empty input and rerunning fd on each keystroke through the change:reload binding refreshes results as you type.
      function cdf() {
        local search_dir="''${1:-~}"
        local target
        target=$(echo "" | fzf --bind "change:reload:fd --follow ${fdExcludes}{q} ''$search_dir 2>/dev/null || true" --header="Type to search, Enter to cd" --preview '([[ -d {} ]] && ls -la {}) || ([[ -f {} ]] && head -20 {})' --height 40% --ansi)
        if [[ -n "$target" ]]; then
          [[ -d "$target" ]] && cd "$target" || cd "$(dirname "$target")"
        fi
      }

      function batf() {
        local search_dir="''${1:-~}"
        local target
        target=$(echo "" | fzf --bind "change:reload:fd --follow ${fdExcludes}{q} ''$search_dir 2>/dev/null || true" --header="Type to search, Enter to view with bat" --preview '([[ -d {} ]] && ls -la {}) || ([[ -f {} ]] && head -20 {})' --height 40% --ansi)
        if [[ -n "$target" ]]; then
          bat "$target"
        fi
      }

      function fm() {
        local current_dir="$(pwd)"
        ${if pkgs.stdenv.isDarwin then
          "open -R \"$current_dir\""
        else
          "thunar \"$current_dir\" &"}
      }

    '';
  };
  
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

      # Clear the file based detection so the segment shows only when a virtualenv is active, instead of in every directory that holds python files.
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
