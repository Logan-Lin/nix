{ config, pkgs, ... }:

{
  # Enable git-credential-oauth for GitHub, GitLab, BitBucket
  programs.git-credential-oauth = {
    enable = true;
  };
  programs.git = {
    enable = true;
    
    userName = "Yan Lin";
    userEmail = "github@yanlincs.com";
    
    ignores = [
      # Claude Code
      "**/.claude/settings.local.json"
      
      # macOS
      ".DS_Store"
      
      # Editors
      ".vscode/"
      ".idea/"
      
      # Development
      "node_modules/"
      ".env"
      ".env.local"
      ".env.*.local"
    ];
    
    extraConfig = {
      # Platform-specific credential configuration
      credential = {
        # OAuth platforms (handled by git-credential-oauth)
        "https://github.com".helper = "oauth";
        "https://gitlab.com".helper = "oauth";
        "https://bitbucket.org".helper = "oauth";
        
        # Token-based platforms
        "https://git.overleaf.com".helper = "store";
        "https://git.overleaf.com".username = "git";
      };
      
      core = {
        editor = "nvim";
        autocrlf = "input";
        ignorecase = false;
      };
      
      init.defaultBranch = "main";
      
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      
      pull = {
        rebase = true;
      };
      
      merge = {
        conflictstyle = "diff3";
      };
      
      diff = {
        colorMoved = "default";
      };
      
      status = {
        showUntrackedFiles = "all";
      };
    };
    
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";
      
      # Better logging
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      lga = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
      
      # Quick operations
      up = "pull --rebase";
      cm = "commit -m";
      ca = "commit --amend";
      
      # Show changes
      d = "diff";
      dc = "diff --cached";
      ds = "diff --stat";
      
      # Stash operations
      sl = "stash list";
      sp = "stash pop";
      ss = "stash save";
    };
  };
}
