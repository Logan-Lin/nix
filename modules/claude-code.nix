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
      "WebSearch"
      "WebFetch(domain:github.com)"
      "Read(/Users/yanlin/.claude/**)"
      "Read(/Users/yanlin/.claude/**)"
    ];
    deny = [];
    ask = [];
  };

  # Global settings configuration
  globalSettings = {
    model = cfg.model;
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
  '';

  # Global memory configuration
  globalMemoryContent = if cfg.globalMemory != null then cfg.globalMemory else defaultGlobalMemory;

in

{
  options.programs.claude-code-custom = {
    enable = mkEnableOption "Claude Code AI assistant";

    model = mkOption {
      type = types.str;
      default = "sonnet";
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
