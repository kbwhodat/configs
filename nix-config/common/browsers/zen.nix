{ inputs, config, pkgs, ... }:
let
inherit (pkgs.stdenv) isDarwin;
in
{

  imports = [
    ../../modules/zen.nix
  ];

  programs.zen-browser.enable =
    if isDarwin then
      true
    else
      true;

  programs.zen-browser.package =
    if isDarwin then
        pkgs.zen-browser-bin-darwin.override {
        nativeMessagingHosts = [
            # Tridactyl native connector
            pkgs.tridactyl-native
        ];
        }
    else
        inputs.zen-browser.packages.x86_64-linux.default.override {
        nativeMessagingHosts = [
            # Gnome shell native connector
            pkgs.gnome-browser-connector
            # Tridactyl native connector
            pkgs.tridactyl-native
        ];
        };

  programs.zen-browser.profiles =
    let

# Using my own custom chrome.css
    userChrome = builtins.readFile ../../../chrome/zen-browser-theme.css;

    name = "kato";
    path = "main";

  isDefault = true;
  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      consent-o-matic
      sponsorblock
      df-youtube
      kagi-search
      darkreader
      # browserpass
      privacy-badger
      onepassword-password-manager
      ublock-origin
      vimium-c
      clearurls
      istilldontcareaboutcookies
      firenvim
      keepassxc-browser
  ];

  settings = {
      
    # Disabling hardware acceleration
    "browser.preferences.defaultPerformanceSettings.enabled" = false;
    "layers.acceleration.disabled" = true;

    # Zen settings
    "browser.tabs.allow_transparent_browser" = true;
    "zen.theme.content-element-separation" = 0;
    "zen.themes.color-prefs.amoled" = true;
    "theme.better_uniexbtn.custom" = "url(chrome://branding/content/icon32.png)";
    "theme.better_uniexbtn.default" = "Default";
    "zen.welcome-screen.seen" = true;
    "zen.welcome-screen.enabled" = false;
    "zen.theme.pill-button" = false;
    "zen.themes.updated-value-observer" = true;
    "zen.urlbar.behavior" = "floating-on-type";
    "zen.view.compact" = true;
    "browser.tabs.hoverPreview.enabled" = true;
    "zen.theme.accent-color" = "#dec663";
    "zen.view.sidebase-expanded" = false;
    "zen.view.sidebase-expanded.on-hover" = true;
    "zen.view.sidebar-expanded" = false;
    "zen.view.use-single-toolbar" = false;
    "zen.splitView.change-on-hover" = true;
    "zen.tab-unloader.timeout-minutes" = 35;
    "zen.view.compact.toolbar-flash-popup" = false;

    "zen.view.compact.hide-tabbar" = true;
    "zen.view.compact.hide-toolbar" = false;
    # Makes some website dark
    "layout.css.prefers-color-scheme.content-override" = 0;

    "browser.theme.toolbar-theme" = 0;
    "browser.theme.content-theme" = 0;
    "ui.systemUsesDarkTheme" = 1;

    "extension.activeThemeID" = "firefox-compact-dark@mozilla.org";
# setting up kagi
    "extensions.webextensions.ExtensionStorageIDB.migrated.search@kagi.com" = true;

# Prevents the alt/command key from showing the menu bar. Gets annoying at time.
    "ui.key.menuAccessKeyFocuses" = false;

# fonts
    "browser.display.use_document_fonts" = 1;
    "font.default.x-western" = "sans-serif";
    "font.size.variable.x-western" = 17;
    "font.name.monospace.x-western" = "ComicShannsMono Nerd Font Mono";
    "font.name.sans-serif.x-western" = " ComicShannsMono Nerd Font Propo";
    "font.name.serif.x-western" = "ComicShannsMono Nerd Font Propo";
    "layout.css.devPixelsPerPx" = 1.0;

    "app.update.auto" = true;
    "browser.toolbars.bookmarks.visibility" = "newtab";
    "browser.urlbar.placeholderName.private" = "Kagi";
    "browser.firefox-view.feature-tour" = "{'screen':'','complete':true}";
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "kagi";
    "browser.newtabpage.pinned" = "[{'url':'https://kagi.com','label':'@kagi','searchTopSite':true}]";
    "browser.bookmarks.addedImportButton" = true;
    "browser.startup.homepage" = "about:blank";
    "browser.search.region" = "US";
    "network.http.http3.enabled" = false;
    "dom.image-lazy-loading.enabled" = true;
# "network.prefetch-next" = false;
    "general.smoothScroll" = true;
    "media.autoplay.default" = 1;
    "browser.cache.disk.enable" = true;
    "broswer.cache.memory.enable" = true;
    "broswer.sessionstore.resume_from_crash" = false;
    "browser.search.countryCode" = "US";
    "browser.search.isUS" = true;
    "browser.ctrlTab.recentlyUsedOrder" = true;
    "browser.ctrlTab.sortByRecentlyUsed" = true;
    "browser.newtabpage.enabled" = false;
    "browser.bookmarks.showMobileBookmarks" = true;
    "browser.uidensity" = 1;
    "browser.urlbar.placeholderName" = "search for something man";
    "browser.urlbar.update1" = true;
    "extensions.pocket.enable" = false;
    "extensions.pocket.showHome" = false;
    "distribution.searchplugins.defaultLocale" = "en-US";
    "general.useragent.locale" = "en-US";
    "identity.fxaccounts.account.device.name" = config.home.username;
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.trackingprotection.socialtracking.annotate.enabled" = true;
    "reader.color_scheme" = "auto";
    "services.sync.declinedEngines" = "addons,passwords,prefs";
    "services.sync.engine.addons" = false;
    "services.sync.engineStatusChanged.addons" = true;
    "services.sync.engine.passwords" = false;
    "services.sync.engine.prefs" = false;
    "services.sync.engineStatusChanged.prefs" = true;
    "signon.rememberSignons" = true;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    /****************************************************************************
     * SECTION: FASTFOX                                                         *
     ****************************************************************************/
    /** GENERAL ***/
    "content.notify.interval" = 200000;

    /** GFX ***/
    "layers.acceleration.enabled" = true;
    "gfx.canvas.accelerated.cache-items" = 4096;
    "gfx.canvas.accelerated.cache-size" = 512;
    "gfx.content.skia-font-cache-size" = 20;

    /** DISK CACHE ***/
    "browser.cache.jsbc_compression_level" = 3;

    /** MEDIA CACHE ***/
    "media.memory_cache_max_size" = 65536;
    "media.cache_readahead_limit" = 7200;
    "media.cache_resume_threshold" = 3600;

    /** IMAGE CACHE ***/
    "image.mem.decode_bytes_at_a_time" = 32768;

    /** NETWORK ***/
    "network.http.max-connections" = 1800;
    "network.http.max-persistent-connections-per-server" = 10;
    "network.http.max-urgent-start-excessive-connections-per-host" = 5;
    "network.http.pacing.requests.enabled" = false;
    "network.dnsCacheExpiration" = 3600;
    "network.ssl_tokens_cache_capacity" = 10240;

    /** SPECULATIVE LOADING ***/
    "network.dns.disablePrefetch" = true;
    "network.dns.disablePrefetchFromHTTPS" = true;
    "network.prefetch-next" = true;
    "network.predictor.enabled" = false;
    "network.predictor.enable-prefetch" = false;

    /** EXPERIMENTAL ***/
    "layout.css.grid-template-masonry-value.enabled" = true;
    "dom.enable_web_task_scheduling" = true;
    "dom.security.sanitizer.enabled" = true;

    /****************************************************************************
     * SECTION: SECUREFOX                                                       *
     ****************************************************************************/
    /** TRACKING PROTECTION ***/
    "browser.contentblocking.category" = "strict";
    "urlclassifier.trackingSkipURLs" = "*.reddit.com, *.twitter.com, *.twimg.com, *.tiktok.com";
    "urlclassifier.features.socialtracking.skipURLs" = "*.instagram.com, *.twitter.com, *.twimg.com";
    "network.cookie.sameSite.noneRequiresSecure" = true;
    "browser.download.start_downloads_in_tmp_dir" = true;
    "browser.helperApps.deleteTempFileOnExit" = true;
    "browser.uitour.enabled" = false;
    "privacy.globalprivacycontrol.enabled" = true;

    /** OCSP & CERTS / HPKP ***/
    "security.OCSP.enabled" = 0;
    "security.remote_settings.crlite_filters.enabled" = true;
    "security.pki.crlite_mode" = 2;

    /** SSL / TLS ***/
    "security.ssl.treat_unsafe_negotiation_as_broken" = true;
    "browser.xul.error_pages.expert_bad_cert" = true;
    "security.tls.enable_0rtt_data" = false;

    /** DISK AVOIDANCE ***/
    "browser.privatebrowsing.forceMediaMemoryCache" = true;
    "browser.sessionstore.interval" = 60000;

    /** SHUTDOWN & SANITIZING ***/
    "privacy.history.custom" = true;

    /** SEARCH / URL BAR ***/
    "browser.search.separatePrivateDefault.ui.enabled" = true;
    "browser.urlbar.update2.engineAliasRefresh" = true;
    "browser.search.suggest.enabled" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.formfill.enable" = false;
    "security.insecure_connection_text.enabled" = true;
    "security.insecure_connection_text.pbmode.enabled" = true;
    "network.IDN_show_punycode" = true;

    /** HTTPS-FIRST POLICY ***/
    "dom.security.https_first" = true;
    "dom.security.https_first_schemeless" = true;

    /** PASSWORDS ***/
    "signon.formlessCapture.enabled" = false;
    "signon.privateBrowsingCapture.enabled" = false;
    "network.auth.subresource-http-auth-allow" = 1;
    "editor.truncate_user_pastes" = false;

    /** MIXED CONTENT + CROSS-SITE ***/
    "security.mixed_content.block_display_content" = true;
    "security.mixed_content.upgrade_display_content" = true;
    "security.mixed_content.upgrade_display_content.image" = true;
    "pdfjs.enableScripting" = false;
    "extensions.postDownloadThirdPartyPrompt" = false;

    /** HEADERS / REFERERS ***/
    "network.http.referer.XOriginTrimmingPolicy" = 2;

    /** CONTAINERS ***/
    "privacy.userContext.ui.enabled" = true;

    /** WEBRTC ***/
    "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
    "media.peerconnection.ice.default_address_only" = true;

    /** SAFE BROWSING ***/
    "browser.safebrowsing.downloads.remote.enabled" = false;

    /** MOZILLA ***/
    "permissions.default.desktop-notification" = 2;
    "permissions.default.geo" = 2;
    "geo.provider.network.url" = "https://location.services.mozilla.com/v1/geolocate?key=%MOZILLA_API_KEY%";
    "permissions.manager.defaultsUrl" = "";
    "webchannel.allowObject.urlWhitelist" = "";

    /** TELEMETRY ***/
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.healthreport.uploadEnabled" = false;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "data:,";
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.telemetry.coverage.opt-out" = true;
    "toolkit.coverage.opt-out" = true;
    "toolkit.coverage.endpoint.base" = "";
    "browser.newtabpage.activity-stream.feeds.telemetry" = false;
    "browser.newtabpage.activity-stream.telemetry" = false;

    /** EXPERIMENTS ***/
    "app.shield.optoutstudies.enabled" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";

    /** CRASH REPORTS ***/
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;

    /** DETECTION ***/
    "captivedetect.canonicalURL" = "";
    "network.captive-portal-service.enabled" = false;
    "network.connectivity-service.enabled" = false;

    /****************************************************************************
     * SECTION: PESKYFOX                                                        *
     ****************************************************************************/
    /** MOZILLA UI ***/
    "browser.privatebrowsing.vpnpromourl" = "";
    "extensions.getAddons.showPane" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    "browser.discovery.enabled" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
    "browser.preferences.moreFromMozilla" = false;
    "browser.tabs.tabmanager.enabled" = false;
    "browser.aboutConfig.showWarning" = false;
    "browser.aboutwelcome.enabled" = false;

    /** THEME ADJUSTMENTS ***/
    "browser.compactmode.show" = true;
    "browser.tabs.groups.enabled" = true;
    "browser.tabs.groups.smart.enabled" = true;
    "browser.display.focus_ring_on_anything" = true;
    "browser.display.focus_ring_style" = 0;
    "browser.display.focus_ring_width" = 0;
    "browser.privateWindowSeparation.enabled" = false;

    /** COOKIE BANNER HANDLING ***/
    "cookiebanners.service.mode" = 1;
    "cookiebanners.service.mode.privateBrowsing" = 1;

    /** FULLSCREEN NOTICE ***/
    "full-screen-api.transition-duration.enter" = "0 0";
    "full-screen-api.transition-duration.leave" = "0 0";
    "full-screen-api.warning.delay" = -1;
    "full-screen-api.warning.timeout" = 0;

    /** URL BAR ***/
    "browser.urlbar.suggest.calculator" = true;
    "browser.urlbar.unitConversion.enabled" = true;
    "browser.urlbar.trending.featureGate" = false;

    /** NEW TAB PAGE ***/
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;

    /** POCKET ***/
    "extensions.pocket.enabled" = false;

    /** DOWNLOADS ***/
    "browser.download.always_ask_before_handling_new_types" = true;
    "browser.download.manager.addToRecentDocs" = false;

    /** PDF ***/
    "browser.download.open_pdf_attachments_inline" = true;

    /** TAB BEHAVIOR ***/
    "browser.bookmarks.openInTabClosesMenu" = false;
    "browser.menu.showViewImageInfo" = true;
    "findbar.highlightAll" = true;
    "layout.word_select.eat_space_to_next_word" = false;


  };
  in
  {
    home = {
      inherit isDefault userChrome settings path extensions name;
      id = 0;
    };
  };

}
