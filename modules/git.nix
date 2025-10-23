{ config, pkgs, ... }:

{
  # Enable git-credential-oauth for GitHub, GitLab, BitBucket
  programs.git-credential-oauth = {
    enable = true;
  };
  programs.git = {
    enable = true;

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

    settings = {
      user = {
        name = "Yan Lin";
        email = "github@yanlincs.com";
      };

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
  };
}
