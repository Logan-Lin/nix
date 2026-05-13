{ config, pkgs, lib, ... }@args:

with lib;

let
  cfg = config.programs.firefox-custom;

  firefox-addons = args.inputs.firefox-addons or null;
  system = pkgs.stdenv.hostPlatform.system;

  extensions =
    if firefox-addons != null then
      with firefox-addons.packages.${system}; [
        ublock-origin
        vimium
        darkreader
        cookies-txt
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

        bookmarks = {
          force = true;
          settings = [{
            name = "Toolbar";
            toolbar = true;
            bookmarks = [{ name = "DuckDuckGo"; url = "https://duckduckgo.com/"; }];
          }];
        };

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

          "permissions.default.geo" = 2;
          "permissions.default.desktop-notification" = 2;

          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          "browser.tabs.loadInBackground" = true;
          "browser.ctrlTab.recentlyUsedOrder" = true;

          "browser.toolbars.bookmarks.visibility" = "never";

          "browser.download.useDownloadDir" = true;
          "browser.download.always_ask_before_handling_new_types" = false;
          "browser.download.open_pdf_attachments_inline" = false;
          "browser.helperApps.deleteTempFileOnExit" = true;

          "dom.security.https_only_mode" = false;
          "dom.security.https_only_mode_ever_enabled" = false;

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

          "experiments.activeExperiment" = false;
          "experiments.enabled" = false;
          "experiments.supported" = false;
          "network.allow-experiments" = false;

          "extensions.pocket.enabled" = false;
          "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;

          "signon.rememberSignons" = false;
          "signon.autofillForms" = false;
          "signon.prefillForms" = false;

          "browser.formfill.enable" = false;
          "browser.formfill.saveHttpsForms" = false;

          "extensions.formautofill.addresses.enabled" = false;
          "extensions.formautofill.creditCards.enabled" = false;
          "extensions.formautofill.heuristics.enabled" = false;

          "browser.tabs.firefox-view" = false;
          "browser.tabs.firefox-view-max-entries" = 0;
          "browser.tabs.firefox-view-next" = false;
          "browser.firefox-view.feature-tour" = "{\"screen\":\"\",\"complete\":true}";
          "browser.firefox-view.view-count" = 0;
          "identity.fxaccounts.enabled" = false;

          "browser.urlbar.suggest.searches" = false;
          "browser.urlbar.suggest.engines" = false;
          "browser.urlbar.quicksuggest.enabled" = false;
          "browser.urlbar.quicksuggest.sponsored" = false;
          "browser.urlbar.quicksuggest.dataCollection.enabled" = false;
          "browser.search.suggest.enabled" = false;

          "browser.urlbar.suggest.clipboard" = false;
          "browser.urlbar.suggest.topsites" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;

          "browser.urlbar.suggest.history" = true;
          "browser.urlbar.maxHistoricalSearchSuggestions" = 3;

          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          "sidebar.visibility" = "always-show";
          "sidebar.main.tools" = "";

          "intl.accept_languages" = "en-US,en,zh-CN,zh-TW,zh-HK,zh";
          "browser.translations.automaticallyPopup" = false;

          "dom.webmidi.enabled" = true;
          "dom.webmidi.gated" = false;

          "browser.ml.enable" = false;
          "browser.ml.chat.enabled" = false;
          "browser.ml.chat.shortcuts" = false;

          "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

          "browser.mailto.dualPrompt" = false;
          "network.protocol-handler.external.mailto" = false;
          "network.protocol-handler.external.webcal" = false;
          "network.protocol-handler.external.tel" = false;

          "browser.shell.checkDefaultBrowser" = false;

          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;

          "signon.management.page.breach-alerts.enabled" = false;
          "browser.contentblocking.report.monitor.enabled" = false;

          "browser.messaging-system.whatsNewPanel.enabled" = false;
          "browser.aboutwelcome.enabled" = false;
          "browser.startup.homepage_override.mstone" = "ignore";

          "browser.vpn_promo.enabled" = false;
          "browser.promo.focus.enabled" = false;
          "browser.promo.pin.enabled" = false;

          "app.normandy.enabled" = false;
          "app.normandy.api_url" = "";

          "browser.discovery.enabled" = false;
          "extensions.htmlaboutaddons.recommendations.enabled" = false;
          "extensions.getAddons.showPane" = false;

          "browser.tabs.crashReporting.sendReport" = false;
          "browser.crashReports.unsubmittedCheck.enabled" = false;

          "browser.download.alwaysOpenPanel" = false;
          "full-screen-api.warning.timeout" = 0;
        };
      };
    };
  }

  (mkIf pkgs.stdenv.isDarwin {
    launchd.agents.firefox-legacy-profiles = {
      enable = true;
      config = {
        Label = "org.mozilla.firefox.legacy-profiles";
        ProgramArguments = [ "/bin/launchctl" "setenv" "MOZ_LEGACY_PROFILES" "1" ];
        RunAtLoad = true;
      };
    };

    home.activation.firefoxLegacyProfiles = hm.dag.entryAfter [ "writeBoundary" ] ''
      /bin/launchctl setenv MOZ_LEGACY_PROFILES 1 || true
    '';
  })
  ]);
}
