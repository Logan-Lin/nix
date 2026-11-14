{ config, pkgs, lib, ... }@args:

with lib;

let
  cfg = config.programs.librewolf-custom;

  firefox-addons = args.inputs.firefox-addons or null;

  extensions =
    if firefox-addons != null then
      with (firefox-addons.overlays.default pkgs pkgs).firefox-addons; [
        vimium
        sidebery
        linkding-extension
        cookies-txt
        darkreader
      ]
    else [];
in

{
  options.programs.librewolf-custom = {
    enable = mkEnableOption "LibreWolf browser configuration";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.librewolf";
    };
  };

  config = mkIf cfg.enable {
    programs.librewolf = {
      enable = true;
      package = cfg.package;

      profiles.yanlin = {
        id = 0;
        isDefault = true;
        name = "yanlin";

        extensions.packages = extensions;

        userChrome = ''
          :root {
            --toolbox-background-color: #1d2021 !important;
            --toolbox-background-color-inactive: #1d2021 !important;
            --toolbox-background-gradient: none !important;
          }

          #sidebar-container,
          #sidebar-launcher-splitter,
          #sidebar-panel-header {
            display: none !important;
          }

          #sidebar-box:not([sidebar-positionend]) {
            --sidebar-box-start-start-radius: 0 !important;
            border-inline-start: none !important;
          }
        '';

        settings = {
          "privacy.sanitize.sanitizeOnShutdown" = false;

          "browser.toolbars.bookmarks.visibility" = "never";
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "always-show";
          "sidebar.main.tools" = "";

          "browser.download.useDownloadDir" = true;

          "gfx.webrender.all" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          "full-screen-api.warning.timeout" = 0;
          "browser.fullscreen.exit_on_escape" = false;

          "intl.accept_languages" = "en-US,en,zh-CN,zh-TW,zh-HK,zh";
          "browser.translations.automaticallyPopup" = false;

          "privacy.resistFingerprinting" = false;
          "dom.security.https_only_mode.upgrade_local" = false;

          "signon.management.page.breach-alerts.enabled" = false;

          "network.protocol-handler.external.mailto" = false;
          "network.protocol-handler.external.webcal" = false;
          "network.protocol-handler.external.tel" = false;

          "extensions.autoDisableScopes" = 0;
        };
      };
    };
  };
}
