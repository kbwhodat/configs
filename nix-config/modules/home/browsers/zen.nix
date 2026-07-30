{ inputs, config, lib, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{

  imports = [
    ./_extensions/zen.nix
  ];

  # Gated: work hosts disable via profiles/home/work.nix (the wrapper
  # re-signs the app bundle — endpoint-security bait on managed macs).
  programs.zen-browser.enable = config.modules.browsers.zen.enable;

  programs.zen-browser.package =
    if isDarwin then
        # macOS: enable ZenLeap/fx-autoconfig via wrapper.
        # The wrapper re-signs the app bundle after injection.
        pkgs.wrapZenBrowserWithFxAutoconfig inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    else
        # Wrap the zen-browser with fx-autoconfig for ZenLeap support
        pkgs.wrapZenBrowserWithFxAutoconfig inputs.zen-browser.packages.x86_64-linux.default;

  programs.zen-browser.profiles =
    let

# Keep only custom browser chrome theme (preserve all-black styling)
    userChrome = builtins.readFile ./chrome/zen-browser-theme.css;

    name = "kato";
    path = "main";

  isDefault = true;
  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      pwas-for-firefox
      sponsorblock
      proton-pass
      ublock-origin
      df-youtube
      kagi-search
      vimium-c
      clearurls
      # Not packaged in NUR — build from the pinned AMO xpi.  Bump:
      # curl -s https://addons.mozilla.org/api/v5/addons/addon/ultimadark/ \
      #   | jq -r '.current_version | .version, .file.url, .file.hash'
      (pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
        pname = "ultimadark";
        version = "1.6.67";
        addonId = "{7c7f6dea-3957-4bb9-9eec-2ef2b9e5bcec}";
        url = "https://addons.mozilla.org/firefox/downloads/file/4920369/ultimadark-1.6.67.xpi";
        sha256 = "sha256:f6c3a7d7babc56db1b73bc81cad5086766068c7d6ebbbaa58acc4fceb1da6ea4";
        meta = with lib; {
          description = "UltimaDark — aggressive dark mode that rewrites page colors before render";
          license = licenses.mpl20;
          mozPermissions = [ "<all_urls>" ];
          platforms = platforms.all;
        };
      })
  ];
  


  settings = {
      
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
    "zen.tab-unloader.timeout-minutes" = 10;
    "zen.view.compact.toolbar-flash-popup" = false;
    "zen.workspaces.continue-where-left-off" = true;

    "zen.view.compact.hide-tabbar" = true;
    "zen.view.compact.hide-toolbar" = false;
    # Makes some website dark
    "layout.css.prefers-color-scheme.content-override" = 0;

    # Collapse Zen's UI animations to instant transitions — UI-thread CPU saver.
    "ui.prefersReducedMotion" = 1;

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
    "font.name.sans-serif.x-western" = "ComicShannsMono Nerd Font Propo";
    "font.name.serif.x-western" = "ComicShannsMono Nerd Font Propo";
    "layout.css.devPixelsPerPx" = -1.0;

    "app.update.auto" = true;
    "browser.toolbars.bookmarks.visibility" = "newtab";
    "browser.urlbar.placeholderName.private" = "Kagi";
    "browser.firefox-view.feature-tour" = "{'screen':'','complete':true}";
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "kagi";
    "browser.newtabpage.pinned" = "[{'url':'https://kagi.com','label':'@kagi','searchTopSite':true}]";
    "browser.bookmarks.addedImportButton" = true;
    "browser.startup.homepage" = "about:blank";
    "browser.startup.page" = 3;
    "browser.privatebrowsing.autostart" = false;
    "privacy.sanitize.sanitizeOnShutdown" = false;
    "privacy.clearOnShutdown.history" = false;
    "browser.search.region" = "US";
    "network.http.http3.enabled" = true;
    "dom.image-lazy-loading.enabled" = true;
# "network.prefetch-next" = false;
    "general.smoothScroll" = true;
    "media.autoplay.default" = 1;
    "browser.cache.disk.enable" = true;
    "browser.cache.memory.enable" = true;
    # Restore the session after a crash — reliability over cold-start purity.
    "browser.sessionstore.resume_from_crash" = true;
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
    "uc.zenleap.settings" = builtins.toJSON {
      "keys.global.leapMode" = {
        key = ";";
        code = "Semicolon";
        ctrl = true;
        shift = false;
        alt = false;
        meta = false;
      };
      "keys.global.splitFocusLeft" = {
        key = "h";
        code = "KeyH";
        ctrl = false;
        shift = false;
        alt = isDarwin;
        meta = !isDarwin;
      };
      "keys.global.splitFocusDown" = {
        key = "j";
        code = "KeyJ";
        ctrl = false;
        shift = false;
        alt = isDarwin;
        meta = !isDarwin;
      };
      "keys.global.splitFocusUp" = {
        key = "k";
        code = "KeyK";
        ctrl = false;
        shift = false;
        alt = isDarwin;
        meta = !isDarwin;
      };
      "keys.global.splitFocusRight" = {
        key = "l";
        code = "KeyL";
        ctrl = false;
        shift = false;
        alt = isDarwin;
        meta = !isDarwin;
      };
      "keys.global.splitResize" = {
        key = " ";
        code = "Space";
        ctrl = false;
        shift = false;
        alt = isDarwin;
        meta = !isDarwin;
      };
    };
    /****************************************************************************
     * SECTION: MEMORY DIET (shared config, 8GB+ hosts)                         *
     ****************************************************************************/
    # Fewer content processes: 4 generic (default 8), 2 per isolated site
    # (default 4), no preallocated spares. Middle ground for mixed-RAM hosts:
    # processes only spawn as tabs need them, and the unloaders below keep the
    # live-tab count low on small machines, so the extra slots mostly
    # materialize where there's RAM for them.
    "dom.ipc.processCount" = 4;
    "dom.ipc.processCount.webIsolated" = 2;
    "dom.ipc.processPrelaunch.enabled" = false;
    # Explicit defaults: these were previously overridden to force software
    # rendering and are sticky in prefs.js if merely removed.
    "layers.acceleration.disabled" = false;
    "browser.preferences.defaultPerformanceSettings.enabled" = true;
    # a11y engine instantiation costs ~100MB+ when tripped; not used here.
    "accessibility.force_disabled" = 1;
    # Auto-size the in-memory page cache to RAM — Firefox's own per-machine
    # scaling, so small hosts stay capped and big hosts use what they have.
    "browser.cache.memory.capacity" = -1;
    # Only give login/high-value sites their own isolated process instead of
    # every origin — biggest process-count lever short of disabling fission.
    "fission.webContentIsolationStrategy" = 2;
    # Firefox-level unloader (complements zen.tab-unloader): eligible after
    # 1 min idle instead of 10, and unload under system memory pressure.
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.tabs.min_inactive_duration_before_unload" = 60000;
    # Keep the last 2 back/forward pages live in RAM for instant back nav
    # (auto would hold ~8); bfcache entries are evicted under memory pressure.
    "browser.sessionhistory.max_total_viewers" = 2;

    /****************************************************************************
     * SECTION: FASTFOX                                                         *
     ****************************************************************************/
    /** GENERAL ***/
    "content.notify.interval" = 200000;

    /** GFX ***/
    "layers.acceleration.enabled" = true;
    # Stock cache sizes — the FastFox bumps (4096/512MB/20MB) buy speed with RAM.
    "gfx.canvas.accelerated.cache-items" = 2048;
    "gfx.canvas.accelerated.cache-size" = 256;
    "gfx.content.skia-font-cache-size" = 5;

    /** DISK CACHE ***/
    "browser.cache.jsbc_compression_level" = 3;

    /** MEDIA CACHE ***/
    "media.memory_cache_max_size" = 8192;
    "media.cache_readahead_limit" = 7200;
    "media.cache_resume_threshold" = 3600;

    /** IMAGE CACHE ***/
    "image.mem.decode_bytes_at_a_time" = 32768;
    # Keep decoded images mapped >=2 min (default 1) — no re-decode jank
    # when scrolling back up a page.
    "image.mem.shared.unmap.min_expiration_ms" = 120000;

    /** NETWORK ***/
    "network.http.max-connections" = 900;
    "network.http.max-persistent-connections-per-server" = 10;
    "network.http.max-urgent-start-excessive-connections-per-host" = 5;
    "network.http.pacing.requests.enabled" = false;
    # 4 min DNS cache (was 1h): stale entries after a service's IP failover
    # cause connection hangs that look like "browser is slow". OS-level DNS
    # cache still absorbs most lookups.
    "network.dnsCacheExpiration" = 240;
    "network.ssl_tokens_cache_capacity" = 10240;

    /** SPECULATIVE LOADING ***/
    "network.dns.disablePrefetch" = true;
    "network.dns.disablePrefetchFromHTTPS" = true;
    # No speculative loading of pages that may never be visited.
    "network.prefetch-next" = false;
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
    # 30s session snapshots (default 15s, was 60s): bounds crash data loss
    # without the default's write churn. Writes happen off-main-thread.
    "browser.sessionstore.interval" = 30000;
    # Don't load all pinned tabs at once on startup — each loads on first
    # click instead, avoiding the launch-time resource storm.
    "browser.sessionstore.restore_pinned_tabs_on_demand" = true;

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
    # Re-enabled (SecureFox disables these): without portal detection, hotel/
    # cafe wifi silently times out on every page until the portal is found by
    # hand — the worst kind of "delay". Costs periodic pings to Mozilla.
    "captivedetect.canonicalURL" = "http://detectportal.firefox.com/canonical.html";
    "network.captive-portal-service.enabled" = true;
    "network.connectivity-service.enabled" = true;

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
    # ZenLeap configuration
    chromeJS = {
      "zenleap.uc.js" = "${pkgs.zenleap}/js/zenleap.uc.js";
      "zenleap-search-open-url.uc.js" = ./zen-userscripts/zenleap-search-open-url.uc.js;
      "zenleap-unsplit.uc.js" = ./zen-userscripts/zenleap-unsplit.uc.js;
      "zen-workspace-shortcuts.uc.js" = ./zen-userscripts/zen-workspace-shortcuts.uc.js;
      "reddit-to-redlib.uc.js" = ./zen-userscripts/reddit-to-redlib.uc.js;
    };

    chromeCSS = {
      "zenleap.css" = "${pkgs.zenleap}/css/zenleap.css";
    };

    fxAutoconfig = pkgs.zenleap;

  in
  {
    home = {
      inherit isDefault userChrome settings path extensions name chromeJS chromeCSS fxAutoconfig;
      id = 0;
    };
  };

}
