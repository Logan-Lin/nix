# Home-manager module that configures Git and its command line tooling.

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
      ".DS_Store" ".claude/" ".codex/" ".opencode/"
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

  programs.zsh.initContent = ''
    function git-snap() {
      if ! ${config.programs.git.package}/bin/git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Not a git repository" >&2
        return 1
      fi

      ${config.programs.git.package}/bin/git add -A
      if ${config.programs.git.package}/bin/git diff --cached --quiet; then
        echo "Nothing to snapshot"
        return 0
      fi

      local ts=$(${pkgs.coreutils}/bin/date +%Y-%m-%dT%H:%M:%S%z)
      GIT_AUTHOR_DATE="$ts" GIT_COMMITTER_DATE="$ts" ${config.programs.git.package}/bin/git commit -q -m "chore: snapshot $ts"
      echo "Snapshot: $ts"
    }
  '';
}
