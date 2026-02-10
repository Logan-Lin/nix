{ config, pkgs, lib, ... }:

with lib;

let
  # Default global permissions
  defaultPermissions = {
    allow = [
      # Web and search capabilities
      "WebSearch"
      "WebFetch"
      
      # Claude configuration files
      "Read(~/.claude/**)"
      "Write(~/.claude/**)"
      "Edit(~/.claude/**)"
      
      # Git operations (read-only and safe operations)
      "Bash(git status)"
      "Bash(git status:*)"
      "Bash(git log:*)"
      "Bash(git diff:*)"
      "Bash(git show:*)"
      "Bash(git branch:*)"
      "Bash(git remote:*)"
      "Bash(git ls-files:*)"

      # Nix operations
      "Bash(nix-shell:*)"
      "Bash(nix develop:*)"
      "Bash(nix build:*)"
      "Bash(nix run:*)"
      "Bash(nix-env -q:*)"
      "Bash(nix search:*)"

      # File operations (safe read operations)
      "Bash(ls:*)"
      "Bash(find:*)"
      "Bash(grep:*)"
      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(wc:*)"
      "Bash(file:*)"
      "Bash(du:*)"
      "Bash(tree:*)"

      # Development environment info
      "Bash(which:*)"
      "Bash(whereis:*)"
      "Bash(whoami)"
      "Bash(pwd)"
      "Bash(uname:*)"
      "Bash(date)"
      "Bash(echo:*)"
    ];
    
    deny = [
      # Prevent dangerous system operations
      "Bash(rm -rf:*)"
      "Bash(sudo:*)"
      "Bash(su:*)"
      "Bash(chmod +x:*)"
      "Bash(chown:*)"
      "Bash(passwd:*)"
      "Bash(userdel:*)"
      "Bash(useradd:*)"
      "Bash(usermod:*)"
      "Bash(groupadd:*)"
      "Bash(groupdel:*)"
      "Bash(mount:*)"
      "Bash(umount:*)"
      "Bash(fdisk:*)"
      "Bash(mkfs:*)"
      "Bash(dd:*)"

      # Prevent network/security risks
      "Bash(nc:*)"
      "Bash(netcat:*)"
      "Bash(telnet:*)"
      "Bash(ssh:*)"
      "Bash(scp:*)"
      "Bash(rsync:*)"
      "Bash(nmap:*)"

      # Prevent package installations without confirmation
      "Bash(npm install:*)"
      "Bash(npm uninstall:*)"
      "Bash(pip install:*)"
      "Bash(pip uninstall:*)"
      "Bash(cargo install:*)"
      "Bash(brew install:*)"
      "Bash(apt install:*)"
      "Bash(yum install:*)"
      "Bash(pacman -S:*)"

      # Prevent system service manipulation
      "Bash(systemctl:*)"
      "Bash(service:*)"
      "Bash(launchctl:*)"

      # Nix system operations
      "Bash(nixos-rebuild:*)"
      "Bash(nix-collect-garbage:*)"
      "Bash(nix-channel:*)"
      "Bash(oss:*)"
      "Bash(hms:*)"
    ];
    
    ask = [
      # File system modifications
      "Bash(mkdir:*)"
      "Bash(rmdir:*)"
      "Bash(mv:*)"
      "Bash(cp:*)"
      "Bash(touch:*)"

      "Bash(curl:*)"
      "Bash(wget:*)"

      "Read(.env*)"
      "Read(*.env*)"
      "Read(./.env*)"
    ];
  };

  # Global settings configuration (merged with permissions)
  globalSettings = {
    spinnerTipsEnabled = false;
    todoEnabled = true;
    autoCompactEnabled = true;
    alwaysThinkingEnabled = true;
    surveyDisabled = true;
    prefersReducedMotion = true;
    promptSuggestionEnabled = false;
    permissions = defaultPermissions;
  };

in

{
  config = {
    # Install Claude Code package
    home.packages = [
      pkgs.claude-code
      pkgs.poppler-utils
    ];

    # Create global settings file (with permissions included)
    home.file.".claude/settings.json" = {
      text = builtins.toJSON globalSettings;
    };

    # Create global memory file
    home.file.".claude/CLAUDE.md" = {
      text = ''
        ## Environment
        - System is managed with Nix (flakes) for global development runtime
        - Projects may use flake + direnv for project-specific runtimes
        - Common development tools (git, gh, ripgrep, jq, fzf, etc.) are globally available via nix
        - PDF reading is supported (poppler-utils installed)
      '';
    };
  };
}
