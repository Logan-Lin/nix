{ pkgs, ... }:

let
  projectsConfig = import ../config/projects.nix;
  projectLauncher = "/Users/yanlin/.config/nix/scripts/project-launcher.sh";
in
{
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";
    enableVteIntegration = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
    };
    
    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";
      
      # Git aliases
      gs = "git status";
      ga = "git add";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      
      # Modern CLI tools
      ftp = "termscp";
      
      # Zoxide aliases
      zi = "z -i";  # Interactive selection with fzf
      
      # Nix helpers
      hm = "home-manager";
      hms = "home-manager switch --flake ~/.config/nix#yanlin";
      
      # Project shortcuts
      proj = "${projectLauncher}";
    } // (
      # Generate project aliases dynamically
      builtins.listToAttrs (
        builtins.map (projectName: {
          name = projectName;
          value = "${projectLauncher} ${projectName}";
        }) (builtins.attrNames projectsConfig.projects)
      )
    );
    
    initContent = ''
      # Load Powerlevel10k theme
      if [[ -f ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme ]]; then
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      fi
      
      # Load Powerlevel10k configuration (managed by Nix)
      source ~/.p10k.zsh
      
      # Vim mode configuration
      # Reduce delay when switching modes (10ms instead of 400ms)
      export KEYTIMEOUT=1
      
      # Cursor shape changes for vim modes
      function zle-keymap-select {
        case $KEYMAP in
          vicmd)      echo -ne '\e[1 q';;  # block cursor for normal mode
          viins|main) echo -ne '\e[5 q';;  # line cursor for insert mode
        esac
      }
      zle -N zle-keymap-select
      
      # Ensure we start with line cursor in insert mode
      function zle-line-init {
        echo -ne '\e[5 q'
      }
      zle -N zle-line-init
      
      # Fix cursor after each command
      function preexec {
        echo -ne '\e[5 q'
      }
      
      # Additional vim-like bindings
      bindkey -M vicmd 'k' history-search-backward
      bindkey -M vicmd 'j' history-search-forward
      bindkey -M vicmd '/' history-incremental-search-backward
      bindkey -M vicmd '?' history-incremental-search-forward
      
      # Better word movement in insert mode
      bindkey '^[[1;5C' forward-word      # Ctrl+Right
      bindkey '^[[1;5D' backward-word     # Ctrl+Left
      
      # Fix backspace in vim insert mode
      bindkey '^?' backward-delete-char   # Backspace
      bindkey '^H' backward-delete-char   # Ctrl+H (alternative backspace)
      
      # Prevent Shift+A from triggering autocomplete in vim insert mode
      # Try multiple potential key sequences for Shift+A across different terminals
      bindkey -M viins 'A' self-insert
      bindkey -M viins '^[[1;2A' self-insert
      bindkey -M viins '^[[65;2u' self-insert
      
      # Disable expand-or-complete on potential problematic keys in vim insert mode
      bindkey -M viins '^I' expand-or-complete   # Keep tab completion but be explicit
      
      # Configure autosuggestions to not interfere with vim mode
      ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(vi-add-eol)
      ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(vi-add-next)
      ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(end-of-line vi-end-of-line vi-add-eol)
      
      # Zoxide configuration - replace cd with z for smart directory jumping
      eval "$(zoxide init zsh --cmd cd)"
    '';
  };
  
  # Essential packages for enhanced zsh experience
  home.packages = with pkgs; [
    zsh-powerlevel10k
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
  
  # Manage Powerlevel10k configuration
  home.file.".p10k.zsh".source = ../config/p10k.zsh;
  
  # Generate projects.json for shell scripts
  home.file.".config/nix/config/projects.json".text = builtins.toJSON projectsConfig;
}