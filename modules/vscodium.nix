{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.vscodium-custom;
in

{
  options.programs.vscodium-custom = {
    enable = mkEnableOption "VSCodium editor configuration";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.vscodium";
      description = "VSCodium package to use. Set to null on Darwin to use Homebrew-installed VSCodium, or pkgs.vscodium on NixOS.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      programs.vscodium = {
        enable = true;
        package = cfg.package;
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            jdinhlife.gruvbox
            vscodevim.vim
          ];
          userSettings = {
            "editor.fontFamily" = "'JetBrainsMono Nerd Font Mono', 'Noto Sans CJK SC', 'Noto Sans CJK TC', 'Noto Sans CJK JP'";
            "editor.fontSize" = 14;
            "editor.tabSize" = 2;
            "editor.wordWrap" = "on";
            "vim.useSystemClipboard" = true;
            "workbench.colorTheme" = "Gruvbox Dark Hard";
          };
        };
      };
    }

    # With package set to null, the vscodium module skips its hook that rebuilds VSCodium's extension list, so run it against the Homebrew CLI whenever the declared extensions change.
    (mkIf (cfg.package == null) {
      home.file.".vscode-oss/extensions/.extensions-immutable.json" = {
        text = pkgs.vscode-utils.toExtensionJson config.programs.vscodium.profiles.default.extensions;
        onChange = ''
          if [ -x /opt/homebrew/bin/codium ]; then
            run rm $VERBOSE_ARG -f .vscode-oss/extensions/{extensions.json,.init-default-profile-extensions,.obsolete}
            run /opt/homebrew/bin/codium --list-extensions > /dev/null
          fi
        '';
      };
    })
  ]);
}
