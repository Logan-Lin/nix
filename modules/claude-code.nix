{ config, pkgs, lib, ... }:

with lib;

let
  defaultPermissions = {
    allow = [
      "WebSearch"
      "WebFetch"
      "Read"
      "Glob"
      "Grep"
      "Write(~/.claude/**)"
      "Edit(~/.claude/**)"
      
      "Bash(git status)"
      "Bash(git status:*)"
      "Bash(git log:*)"
      "Bash(git diff:*)"
      "Bash(git show:*)"
      "Bash(git branch:*)"
      "Bash(git remote:*)"
      "Bash(git ls-files:*)"
      "Bash(gh api:*)"

      "Bash(nix-shell:*)"
      "Bash(nix develop:*)"
      "Bash(nix build:*)"
      "Bash(nix run:*)"
      "Bash(nix-env -q:*)"
      "Bash(nix search:*)"

      "Bash(builtin cd:*)"
      "Bash(cd:*)"
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
      "Bash(pdftotext:*)"

      "Bash(* | head:*)"
      "Bash(* | tail:*)"
      "Bash(* | wc:*)"
      "Bash(* | grep:*)"
      "Bash(* | cat:*)"

      "Bash(which:*)"
      "Bash(whereis:*)"
      "Bash(whoami)"
      "Bash(pwd)"
      "Bash(uname:*)"
      "Bash(date)"
      "Bash(echo:*)"
    ];
    
    deny = [
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

      "Bash(nc:*)"
      "Bash(netcat:*)"
      "Bash(telnet:*)"
      "Bash(ssh:*)"
      "Bash(scp:*)"
      "Bash(rsync:*)"
      "Bash(nmap:*)"

      "Bash(npm install:*)"
      "Bash(npm uninstall:*)"
      "Bash(pip install:*)"
      "Bash(pip uninstall:*)"
      "Bash(cargo install:*)"
      "Bash(brew install:*)"
      "Bash(apt install:*)"
      "Bash(yum install:*)"
      "Bash(pacman -S:*)"

      "Bash(systemctl:*)"
      "Bash(service:*)"
      "Bash(launchctl:*)"

      "Bash(nixos-rebuild:*)"
      "Bash(nix-collect-garbage:*)"
      "Bash(nix-channel:*)"
      "Bash(oss:*)"
      "Bash(hms:*)"
    ];
    
    additionalDirectories = [
      "~/Documents/"
    ];

    ask = [
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
    home.packages = [
      pkgs.claude-code
      pkgs.poppler-utils
      pkgs.pandoc
      pkgs.yq-go
    ];

    home.file.".claude/settings.json" = {
      text = builtins.toJSON globalSettings;
    };

    home.file.".claude/CLAUDE.md" = {
      text = ''
        ## Environment
        - System is managed with Nix (flakes) for global development runtime
        - Projects may use flake + direnv for project-specific runtimes
        - `cd` is aliased to `zoxide`, use `builtin cd` for chaning directories in bash commands; do not use `builtin` prefix for other bash commands
        - Common development tools (git, gh, ripgrep, jq, fzf, etc.) are globally available via nix
        - When the Read tool broke on PDF files, use `pdftotext <file> -` via Bash instead
        - Document format conversion is supported (pandoc installed)
        - YAML/TOML/XML processing is supported (yq-go installed)
      '';
    };
  };
}
