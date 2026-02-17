{ config, pkgs, ... }:

{
  home.packages = [
    pkgs.gh
  ];

  programs.git-credential-oauth = {
    enable = true;
  };

  programs.git = {
    enable = true;

    ignores = [
      "**/.claude/settings.local.json"
      ".DS_Store"
      ".env"
      "node_modules/"
      ".venv/"
      "__pycache__/"
    ];

    settings = {
      user = {
        name = "Yan Lin";
        email = "github@yanlincs.com";
      };

      credential = {
        "https://github.com".helper = "oauth";
        "https://gitlab.com".helper = "oauth";
        "https://bitbucket.org".helper = "oauth";
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
