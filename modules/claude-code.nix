{ config, pkgs, lib, claude-code, ... }:

with lib;

let
  cfg = config.programs.claude-code-custom;
  
  # Detect system architecture and select appropriate package
  claudePackage = if pkgs.system == "aarch64-darwin" then
    claude-code.packages.aarch64-darwin.claude-code
  else if pkgs.system == "x86_64-linux" then
    claude-code.packages.x86_64-linux.claude-code
  else
    throw "Unsupported system for Claude Code: ${pkgs.system}";

  # Default global permissions
  defaultPermissions = {
    allow = [
      # Web and search capabilities
      "WebSearch"
      "WebFetch(domain:github.com)"
      "WebFetch(domain:docs.github.com)"
      "WebFetch(domain:api.github.com)"
      "WebFetch(domain:raw.githubusercontent.com)"
      
      # Claude configuration files
      "Read(/Users/yanlin/.claude/**)"
      "Write(/Users/yanlin/.claude/**)"
      "Edit(/Users/yanlin/.claude/**)"
      
      # Git operations (read-only and safe operations)
      "Bash(git status)"
      "Bash(git log*)"
      "Bash(git diff*)"
      "Bash(git show*)"
      "Bash(git branch*)"
      "Bash(git remote*)"
      "Bash(git ls-files*)"
      
      # Development tools - testing and linting
      "Bash(npm run test*)"
      "Bash(npm run lint*)"
      "Bash(npm run format*)"
      "Bash(npm run check*)"
      
      # Package managers (read-only operations)
      "Bash(npm list*)"
      "Bash(npm outdated*)"
      "Bash(cargo --version)"
      "Bash(pip list*)"
      "Bash(pip show*)"

      # Homebrew (read-only operations)
      "Bash(brew --version)"
      "Bash(brew list*)"
      "Bash(brew info*)"
      "Bash(brew search*)"
      "Bash(brew outdated*)"
      "Bash(brew deps*)"
      "Bash(brew doctor)"
      "Bash(brew config)"
      
      # Nix operations
      "Bash(nix-shell*)"
      "Bash(nix develop*)"
      "Bash(nix build*)"
      "Bash(nix run*)"
      "Bash(nix-env -q*)"
      "Bash(nix search*)"
      
      # File operations (safe read operations)
      "Bash(ls*)"
      "Bash(find*)"
      "Bash(grep*)"
      "Bash(cat*)"
      "Bash(head*)"
      "Bash(tail*)"
      "Bash(wc*)"
      "Bash(file*)"
      "Bash(du*)"
      "Bash(tree*)"
      
      # Development environment info
      "Bash(which*)"
      "Bash(whereis*)"
      "Bash(whoami)"
      "Bash(pwd)"
      "Bash(uname*)"
      "Bash(date)"
      "Bash(echo*)"
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
      "Bash(rm -rf*)"
      "Bash(sudo*)"
      "Bash(su*)"
      "Bash(chmod +x*)"
      "Bash(chown*)"
      "Bash(passwd*)"
      "Bash(userdel*)"
      "Bash(useradd*)"
      "Bash(usermod*)"
      "Bash(groupadd*)"
      "Bash(groupdel*)"
      "Bash(mount*)"
      "Bash(umount*)"
      "Bash(fdisk*)"
      "Bash(mkfs*)"
      "Bash(dd*)"
      "Bash(curl*http*)"
      "Bash(wget*http*)"
      
      # Prevent network/security risks
      "Bash(nc*)"
      "Bash(netcat*)"
      "Bash(telnet*)"
      "Bash(ssh*)"
      "Bash(scp*)"
      "Bash(rsync*)"
      "Bash(nmap*)"
      
      # Prevent package installations without confirmation
      "Bash(npm install*)"
      "Bash(npm uninstall*)"
      "Bash(pip install*)"
      "Bash(pip uninstall*)"
      "Bash(cargo install*)"
      "Bash(brew install*)"
      "Bash(apt install*)"
      "Bash(yum install*)"
      "Bash(pacman -S*)"
      
      # Prevent system service manipulation
      "Bash(systemctl*)"
      "Bash(service*)"
      "Bash(launchctl*)"
    ];
    
    ask = [
      # File system modifications
      "Write(*)"
      "Edit(*)"
      "Bash(mkdir*)"
      "Bash(rmdir*)"
      "Bash(mv*)"
      "Bash(cp*)"
      "Bash(touch*)"
      
      # Nix system operations
      "Bash(nixos-rebuild*)"
      "Bash(nix-collect-garbage*)"
      "Bash(nix-channel*)"
      "Bash(oss*)"
      "Bash(hms*)"
    ];
  };

  # Global settings configuration
  globalSettings = {
    model = cfg.model;
    spinnerTipsEnabled = false;
  };

  # Global permissions configuration
  globalPermissions = if cfg.permissions != null then cfg.permissions else defaultPermissions;

  # Default global memory content
  defaultGlobalMemory = ''
    # Global Claude Code Instructions
    - Never write shebang unless specifically requested
    
    ## NixOS
    - I use nixOS for all my computers (global config in ~/.config/nix) and nix-shell for project-specific runtime management
    - Check existing nix config when interacting with runtime environments
    - Use `oss` alias for nixos-rebuild switch (cross-platform, works on both NixOS and nix-darwin)
    - Use `hms` alias for home-manager switch
  '';

  # Global memory configuration
  globalMemoryContent = if cfg.globalMemory != null then cfg.globalMemory else defaultGlobalMemory;

in

{
  options.programs.claude-code-custom = {
    enable = mkEnableOption "Claude Code AI assistant";

    model = mkOption {
      type = types.str;
      default = "opusplan";
      description = "Default model to use with Claude Code";
    };

    permissions = mkOption {
      type = types.nullOr (types.attrsOf (types.listOf types.str));
      default = null;
      description = "Global permissions configuration. If null, uses default permissions.";
    };

    globalMemory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Global memory configuration for Claude Code. Content for ~/.claude/CLAUDE.md file. If null, uses default global memory.";
    };
  };

  config = mkIf cfg.enable {
    # Install Claude Code package
    home.packages = [ claudePackage ];

    # Create global settings file
    home.file.".claude/settings.json" = {
      text = builtins.toJSON globalSettings;
    };

    # Create global permissions file (optional, can be overridden per project)
    home.file.".claude/permissions.json" = {
      text = builtins.toJSON { permissions = globalPermissions; };
    };

    # Create global memory file (always created with default or custom content)
    home.file.".claude/CLAUDE.md" = {
      text = globalMemoryContent;
    };
  };
}
