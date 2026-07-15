# Home-manager module that configures Git and its command line tooling.
# Installs the GitHub CLI and Git LFS, routes credentials through OAuth helpers, and sets global Git defaults and ignore patterns.

{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.gh
    pkgs.git-lfs
  ];

  programs.git-credential-oauth = {
    enable = true;
  };

  programs.git = {
    enable = true;

    signing.format = null;

    # Global ignores so macOS metadata and local AI assistant config never get committed to any repository.
    ignores = [
      ".DS_Store" ".claude/" ".codex/"
      "AGENTS.md" "CLAUDE.md"
    ];

    settings = {
      user = {
        name = "Yan Lin";
        email = "git@yanlincs.com";
      };

      credential = {
        "https://github.com".helper = "oauth";
        "https://gitlab.com".helper = "oauth";
        "https://bitbucket.org".helper = "oauth";
        # Overleaf does not support OAuth, so use the store helper with its fixed git username.
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
