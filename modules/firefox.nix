{ config, pkgs, lib, ... }@args:

{
  programs.firefox = {
    enable = true;
    
    profiles.yanlin = {
      id = 0;
      isDefault = true;
      name = "yanlin";
      
      # Extensions
      extensions = {
        packages = let
          firefox-addons = args.firefox-addons or null;
        in
          if firefox-addons != null then
            with firefox-addons.packages.${pkgs.system}; [
              ublock-origin
              linkding-extension
            ]
          else [];
      };
      
      # Bookmarks
      bookmarks = import ../config/firefox-bookmarks.nix;
      
      # Search configuration
      search = {
        force = true;
        default = "ddg";
        
        # engines = {
        #   "Nix Packages" = {
        #     urls = [{
        #       template = "https://search.nixos.org/packages";
        #       params = [
        #         { name = "channel"; value = "unstable"; }
        #         { name = "query"; value = "{searchTerms}"; }
        #       ];
        #     }];
        #     icon = "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        #     definedAliases = [ "@np" ];
        #   };
        #   
        #   "NixOS Wiki" = {
        #     urls = [{ template = "https://wiki.nixos.org/index.php?search={searchTerms}"; }];
        #     icon = "https://wiki.nixos.org/favicon.png";
        #     definedAliases = [ "@nw" ];
        #   };
        # };
      };
      
      # Firefox settings
      settings = {
        # General preferences
        "browser.startup.homepage" = "about:home";
        "browser.newtabpage.enabled" = true;
        
        # New tab page - show only search bar
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.system.topsites" = false;
        "browser.newtabpage.activity-stream.feeds.system.topstories" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        
        # Privacy settings
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.donottrackheader.enabled" = true;
        
        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        
        # UI preferences
        "browser.tabs.loadInBackground" = true;
        "browser.ctrlTab.recentlyUsedOrder" = true;
        
        # Bookmarks toolbar (only show on new tab/home page)
        "browser.toolbars.bookmarks.visibility" = "newtab";
        
        # Downloads
        "browser.download.useDownloadDir" = false;
        "browser.download.always_ask_before_handling_new_types" = true;
        
        # Security
        "dom.security.https_only_mode" = true;
        "dom.security.https_only_mode_ever_enabled" = true;
        
        # Disable telemetry
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
        
        # Disable experiments
        "experiments.activeExperiment" = false;
        "experiments.enabled" = false;
        "experiments.supported" = false;
        "network.allow-experiments" = false;
        
        # Disable Pocket
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.section.highlights.includePocket" = false;
        
        # Password Manager - disable all functionality
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;
        "signon.prefillForms" = false;
        
        # Form Auto-complete - disable all form history and suggestions
        "browser.formfill.enable" = false;
        "browser.formfill.saveHttpsForms" = false;
        
        # Additional Auto-fill features - disable address and credit card autofill
        "extensions.formautofill.addresses.enabled" = false;
        "extensions.formautofill.creditCards.enabled" = false;
        "extensions.formautofill.heuristics.enabled" = false;
      };
    };
  };
}
