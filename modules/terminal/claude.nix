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
      "Bash(nix eval:*)"
      "Bash(nix flake show:*)"
      "Bash(nix flake metadata:*)"
      "Bash(nix flake check:*)"
      "Bash(nix derivation show:*)"
      "Bash(nix why-depends:*)"

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
      "Bash(dd:*)"
      "Bash(mkfs:*)"
      "Bash(fdisk:*)"
    ];
    
    additionalDirectories = [
      "~/Documents/"
    ];

};

  globalSettings = {
    spinnerTipsEnabled = false;
    todoEnabled = true;
    autoCompactEnabled = true;
    autoMemoryEnabled = false;
    alwaysThinkingEnabled = true;
    surveyDisabled = true;
    prefersReducedMotion = true;
    promptSuggestionEnabled = false;
    effortLevel = "high";
    terminalProgressBarEnabled = false;
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
        - System is managed with Nix for global development runtime, config repo at `~/.config/nix`
        - Projects may use flake + direnv for project-specific runtimes
        - Common development tools (git, gh, ripgrep, jq, fzf, etc.) are globally available via nix
        - When the Read tool broke on PDF files, use `pdftotext <file> -` via Bash instead
        - Document format conversion is supported (pandoc installed)
        - YAML/TOML/XML processing is supported (yq-go installed)
      '';
    };
  };
}
