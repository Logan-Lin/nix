{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    
    userName = "Yan Lin";
    userEmail = "github@yanlincs.com";
    
    ignores = [
      # Claude Code
      "**/.claude/settings.local.json"
      
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "Icon"
      "._*"
      ".DocumentRevisions-V100"
      ".fseventsd"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      ".com.apple.timemachine.donotpresent"
      
      # Editors
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"
      ".vim/"
      
      # Development
      "node_modules/"
      ".env"
      ".env.local"
      ".env.*.local"
      "*.log"
      "npm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"
      
      # Python
      "__pycache__/"
      "*.py[cod]"
      "*$py.class"
      ".Python"
      "build/"
      "develop-eggs/"
      "dist/"
      "downloads/"
      "eggs/"
      ".eggs/"
      "lib/"
      "lib64/"
      "parts/"
      "sdist/"
      "var/"
      "wheels/"
      "*.egg-info/"
      ".installed.cfg"
      "*.egg"
      
      # Temporary files
      "*.tmp"
      "*.temp"
      "*.bak"
      "*.backup"
      "*~"
      
      # OS generated files
      "Thumbs.db"
      "ehthumbs.db"
      "Desktop.ini"
      "$RECYCLE.BIN/"
    ];
    
    extraConfig = {
      credential.helper = "";
      
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