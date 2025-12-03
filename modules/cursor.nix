{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.cursor;

  configDir = if pkgs.stdenv.isDarwin
    then "Library/Application Support/Cursor/User"
    else ".config/Cursor/User";

  cursorCmd = if pkgs.stdenv.isDarwin
    then "/opt/homebrew/bin/cursor"
    else "cursor";

  extensions = [
    "vscodevim.vim"
    "jdinhlife.gruvbox"
    "jnoortheen.nix-ide"
    "tomoki1207.pdf"
  ];

  ideSettings = {
    "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'Noto Sans CJK SC', 'Noto Sans CJK TC', 'Noto Sans CJK JP', monospace";
    "editor.fontSize" = 14;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.wordWrap" = "off";
    "editor.lineNumbers" = "on";
    "editor.autoIndent" = "advanced";

    "workbench.colorTheme" = "Gruvbox Dark Hard";

    "git.openRepositoryInParentFolders" = "never";

    "vim.leader" = "<space>";
    "vim.useSystemClipboard" = true;
    "vim.normalModeKeyBindingsNonRecursive" = [
      { before = ["<leader>" "w"]; commands = ["workbench.action.files.save"]; }
      { before = ["<leader>" "q"]; commands = ["workbench.action.closeActiveEditor"]; }
      { before = ["<leader>" "e"]; commands = ["workbench.action.toggleSidebarVisibility"]; }
      { before = ["<S-h>"]; commands = ["workbench.action.previousEditor"]; }
      { before = ["<S-l>"]; commands = ["workbench.action.nextEditor"]; }
      { before = ["<leader>" "x"]; commands = ["workbench.action.closeActiveEditor"]; }
      { before = ["<leader>" "X"]; commands = ["workbench.action.closeOtherEditors"]; }
      { before = ["<leader>" "t"]; commands = ["workbench.action.quickOpen"]; }
      { before = ["<leader>" "g"]; commands = ["workbench.action.findInFiles"]; }
      { before = ["<leader>" "f"]; commands = ["revealFileInOS"]; }
      { before = ["<C-h>"]; commands = ["workbench.action.focusSideBar"]; }
      { before = ["<C-l>"]; commands = ["workbench.action.focusActiveEditorGroup"]; }
    ];
  };

  cliConfig = {};

in
{
  options.programs.cursor = {
    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.code-cursor";
      description = "Cursor package to use. Set to null on Darwin to use Homebrew-installed Cursor, or pkgs.code-cursor on NixOS.";
    };
  };

  config = {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/settings.json" = {
      text = builtins.toJSON ideSettings;
    };

    home.file.".cursor/cli-config.json" = {
      text = builtins.toJSON cliConfig;
    };

    home.activation.installCursorExtensions = config.lib.dag.entryAfter ["writeBoundary"] ''
      if command -v ${cursorCmd} &> /dev/null; then
        desired="${lib.concatStringsSep " " extensions}"
        installed=$(${cursorCmd} --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

        for ext in $installed; do
          if ! echo "$desired" | tr '[:upper:]' '[:lower:]' | grep -qw "$ext"; then
            run ${cursorCmd} --uninstall-extension "$ext" &> /dev/null || true
          fi
        done

        for ext in ${lib.concatStringsSep " " extensions}; do
          run ${cursorCmd} --install-extension "$ext" &> /dev/null || true
        done
      fi
    '';
  };
}
