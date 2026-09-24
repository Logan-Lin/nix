{ config, pkgs, lib, ... }@args:

with lib;

let
  cfg = config.programs.firefox-custom;

  # firefox-addons is an optional flake input, so install no extensions when it is absent.
  firefox-addons = args.inputs.firefox-addons or null;
  system = pkgs.stdenv.hostPlatform.system;

  extensions =
    if firefox-addons != null then
      with firefox-addons.packages.${system}; [
        ublock-origin
        vimium
      ]
    else [];
in

{
  options.programs.firefox-custom = {
    enable = mkEnableOption "Firefox browser configuration";

    package = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = "pkgs.firefox";
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    programs.firefox = {
      enable = true;
      package = cfg.package;

      profiles.yanlin = {
        id = 0;
        isDefault = true;
        name = "yanlin";

        extensions.packages = extensions;

        search = {
          force = true;
          default = "ddg";
          engines = {
            "google".metaData.hidden = true;
            "bing".metaData.hidden = true;
            "amazondotcom-us".metaData.hidden = true;
            "ebay".metaData.hidden = true;
            "wikipedia".metaData.hidden = true;
            "perplexity".metaData.hidden = true;
          };
        };

        settings = {
          "browser.startup.homepage" = "about:home";
          "browser.startup.page" = 3;
          "browser.newtabpage.enabled" = true;

          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.system.topsites" = false;
          "browser.newtabpage.activity-stream.feeds.system.topstories" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showWeather" = false;

          "browser.tabs.loadInBackground" = true;
          "browser.toolbars.bookmarks.visibility" = "never";
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "always-show";
          "sidebar.main.tools" = "";
          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          "browser.urlbar.suggest.searches" = true;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.suggest.clipboard" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
          "browser.search.suggest.enabled" = true;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "browser.urlbar.suggest.history" = true;
          "browser.urlbar.maxHistoricalSearchSuggestions" = 3;

          "browser.download.useDownloadDir" = true;
          "browser.download.always_ask_before_handling_new_types" = false;
          "browser.download.open_pdf_attachments_inline" = false;
          "browser.download.alwaysOpenPanel" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;

          "permissions.default.geo" = 0;
          "permissions.default.desktop-notification" = 0;

          "gfx.webrender.all" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          "full-screen-api.warning.timeout" = 0;
          "browser.fullscreen.exit_on_escape" = false;

          "dom.webmidi.enabled" = true;
          "dom.webmidi.gated" = false;

          "intl.accept_languages" = "en-US,en,zh-CN,zh-TW,zh-HK,zh";
          "browser.translations.automaticallyPopup" = false;

          "dom.security.https_only_mode" = false;
          "dom.security.https_only_mode_ever_enabled" = false;

          "privacy.trackingprotection.enabled" = false;
          "privacy.trackingprotection.socialtracking.enabled" = false;
          "privacy.trackingprotection.pbmode.enabled" = false;
          "privacy.trackingprotection.cryptomining.enabled" = false;
          "privacy.trackingprotection.fingerprinting.enabled" = false;
          "privacy.trackingprotection.annotate_channels" = false;
          "privacy.donottrackheader.enabled" = false;
          "browser.contentblocking.category" = "custom";
          "network.cookie.cookieBehavior" = 0;
          "privacy.firstparty.isolate" = false;
          "privacy.resistFingerprinting" = false;

          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "browser.formfill.enable" = false;
          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;

          "identity.fxaccounts.enabled" = false;
          "signon.management.page.breach-alerts.enabled" = false;
          "browser.contentblocking.report.monitor.enabled" = false;

          "browser.ml.enable" = false;
          "browser.ml.chat.enabled" = false;
          "browser.ml.chat.shortcuts" = false;

          "browser.mailto.dualPrompt" = false;
          "network.protocol-handler.external.mailto" = false;
          "network.protocol-handler.external.webcal" = false;
          "network.protocol-handler.external.tel" = false;

          "browser.aboutwelcome.enabled" = false;
          "browser.startup.homepage_override.mstone" = "ignore";
          "browser.firefox-view.feature-tour" = builtins.toJSON { screen = ""; complete = true; };
          "browser.shell.checkDefaultBrowser" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
          "browser.vpn_promo.enabled" = false;
          "browser.promo.pin.enabled" = false;

          "browser.discovery.enabled" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.getAddons.showPane" = false;

          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";

          "datareporting.healthreport.uploadEnabled" = false;
          "datareporting.policy.dataSubmissionEnabled" = false;
          "toolkit.telemetry.unified" = false;
          "toolkit.telemetry.enabled" = false;
          "toolkit.telemetry.server" = "data:,";
          "toolkit.telemetry.archive.enabled" = false;
          "toolkit.telemetry.newProfilePing.enabled" = false;
          "toolkit.telemetry.shutdownPingSender.enabled" = false;
          "toolkit.telemetry.updatePing.enabled" = false;
          "toolkit.telemetry.bhrPing.enabled" = false;
          "toolkit.telemetry.firstShutdownPing.enabled" = false;

          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.enabled" = false;
        };
      };
    };
  }

  # The Firefox profile directory differs between platforms, so set it only on Linux.
  (mkIf pkgs.stdenv.hostPlatform.isLinux {
    programs.firefox.configPath = ".mozilla/firefox";
  })
  ]);
}
