{ config, pkgs, lib, ... }:

{
  programs.gemini-cli = {
    enable = true;

    settings = {
      general.previewFeatures = true;

      ui = {
        useFullWidth = true;
        incrementalRendering = true;
        dynamicWindowTitle = true;
      };

      privacy.usageStatisticsEnabled = false;

      tools = {
        sandbox = false;

        # Auto-approved tools (similar to Claude's "allow")
        allowed = [
          "WebFetchTool" "WebSearchTool"
          "ReadFileTool" "GlobTool" "GrepTool"
          "ReadFileTool(~/.gemini/**)" "WriteFileTool(~/.gemini/**)" "EditFileTool(~/.gemini/**)"
          # Git (read-only)
          "run_shell_command(git status)" "run_shell_command(git log)" "run_shell_command(git diff)"
          "run_shell_command(git show)" "run_shell_command(git branch)" "run_shell_command(git remote)"
          # Nix
          "run_shell_command(nix-shell)" "run_shell_command(nix develop)" "run_shell_command(nix build)"
          "run_shell_command(nix run)" "run_shell_command(nix search)"
          # File ops (read-only)
          "run_shell_command(ls)" "run_shell_command(find)" "run_shell_command(grep)"
          "run_shell_command(cat)" "run_shell_command(head)" "run_shell_command(tail)"
          "run_shell_command(wc)" "run_shell_command(file)" "run_shell_command(du)" "run_shell_command(tree)"
          # Environment info
          "run_shell_command(which)" "run_shell_command(whereis)" "run_shell_command(whoami)"
          "run_shell_command(pwd)" "run_shell_command(uname)" "run_shell_command(date)"
        ];

        # Blocked tools (similar to Claude's "deny")
        exclude = [
          # Dangerous system ops
          "run_shell_command(rm -rf)" "run_shell_command(sudo)" "run_shell_command(su)"
          "run_shell_command(chmod +x)" "run_shell_command(chown)" "run_shell_command(dd)"
          # Network risks
          "run_shell_command(nc)" "run_shell_command(netcat)" "run_shell_command(ssh)"
          "run_shell_command(scp)" "run_shell_command(rsync)" "run_shell_command(nmap)"
          # Package installs
          "run_shell_command(npm install)" "run_shell_command(pip install)"
          "run_shell_command(brew install)" "run_shell_command(apt install)"
          # System services
          "run_shell_command(systemctl)" "run_shell_command(service)" "run_shell_command(launchctl)"
          # Nix system ops
          "run_shell_command(nixos-rebuild)" "run_shell_command(nix-collect-garbage)"
          "run_shell_command(oss)" "run_shell_command(hms)"
        ];
      };
    };

    context."GEMINI" = "";
  };
}
