{ config, pkgs, lib, ... }:

let
  configDir = if pkgs.stdenv.isDarwin
    then "Library/Application Support/Cursor/User"
    else ".config/Cursor/User";

  cursorCmd = if pkgs.stdenv.isDarwin
    then "/opt/homebrew/bin/cursor"
    else "cursor";

  ideSettings = {
    "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'Noto Sans CJK SC', 'Noto Sans CJK TC', monospace";
    "editor.fontSize" = 14;
    "editor.tabSize" = 2;
    "editor.insertSpaces" = true;
    "editor.wordWrap" = "off";
    "editor.lineNumbers" = "on";
    "editor.autoIndent" = "advanced";

    "workbench.colorTheme" = "Gruvbox Dark Hard";

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
    ];
  };

  cliConfig = {};

in
{
  config = {
    home.file."${configDir}/settings.json" = {
      text = builtins.toJSON ideSettings;
    };

    home.file.".cursor/cli-config.json" = {
      text = builtins.toJSON cliConfig;
    };

    home.activation.installCursorExtensions = config.lib.dag.entryAfter ["writeBoundary"] ''
      if command -v ${cursorCmd} &> /dev/null; then
        run ${cursorCmd} --install-extension vscodevim.vim 2>/dev/null || true
        run ${cursorCmd} --install-extension jdinhlife.gruvbox 2>/dev/null || true
        run ${cursorCmd} --install-extension jnoortheen.nix-ide 2>/dev/null || true
      fi
    '';
  };
}
