{ config, pkgs, lib, claude-code, ... }:

with lib;

let
  # Detect system architecture and select appropriate package
  claudePackage = if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then
    claude-code.packages.aarch64-darwin.claude-code
  else if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
    claude-code.packages.x86_64-linux.claude-code
  else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
    claude-code.packages.aarch64-linux.claude-code
  else
    throw "Unsupported system for Claude Code: ${pkgs.stdenv.hostPlatform.system}";

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

      # Development tools - testing and linting
      "Bash(npm run test:*)"
      "Bash(npm run lint:*)"
      "Bash(npm run format:*)"
      "Bash(npm run check:*)"

      # Package managers (read-only operations)
      "Bash(npm list:*)"
      "Bash(npm outdated:*)"
      "Bash(cargo --version)"
      "Bash(pip list:*)"
      "Bash(pip show:*)"

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
      # Prevent access to sensitive files
      "Read(.env*)"
      "Read(*.env*)"
      "Read(./.env*)"
      "Read(./secrets/**)"
      "Read(./private/**)"
      "Read(/etc/passwd)"
      "Read(/etc/shadow)"
      "Read(/etc/sudoers*)"
      "Read(~/.ssh/id_*)"
      "Read(~/.gnupg/**)"
      "Read(~/.aws/credentials)"
      "Read(~/.config/gcloud/**)"
      "Read(*/node_modules/.cache/**)"
      
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
      "Bash(curl:*)"
      "Bash(wget:*)"

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
    ];
    
    ask = [
      # File system modifications
      "Write(*)"
      "Edit(*)"
      "Bash(mkdir:*)"
      "Bash(rmdir:*)"
      "Bash(mv:*)"
      "Bash(cp:*)"
      "Bash(touch:*)"

      # Nix system operations
      "Bash(nixos-rebuild:*)"
      "Bash(nix-collect-garbage:*)"
      "Bash(nix-channel:*)"
      "Bash(oss:*)"
      "Bash(hms:*)"
    ];
  };

  # Global settings configuration (merged with permissions)
  globalSettings = {
    spinnerTipsEnabled = false;
    todoEnabled = true;
    autoCompactEnabled = true;
    permissions = defaultPermissions;
  };

in

{
  config = {
    # Install Claude Code package
    home.packages = [ claudePackage ];

    # Create global settings file (with permissions included)
    home.file.".claude/settings.json" = {
      text = builtins.toJSON globalSettings;
    };

    # Create global memory file
    home.file.".claude/CLAUDE.md" = {
      text = "";
    };
  };
}
