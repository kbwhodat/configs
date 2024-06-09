{ config, pkgs, ... }:
let
inherit (pkgs.stdenv) isDarwin;
fullName = "dns issue";
in
{

 imports = [
  ../../modules/floorp.nix
 ];

  programs.floorp.enable = 
    if isDarwin then
      false
    else
      true;

  programs.floorp.package =
    if isDarwin then
# Handled by the Homebrew module
# This populates a dummy package to satsify the requirement
      pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
    else
      pkgs.floorp.override {
         # enableTridactylNative = true;
        nativeMessagingHosts = [
          pkgs.tridactyl-native
          
        ];
      };

  programs.floorp.profiles =
    let
    userChrome = builtins.readFile ../../../chrome/myuserchrome.css;

  extensions = with pkgs.nur.repos.rycee.floorp-addons; [
    browserpass
    consent-o-matic
    sponsorblock
    leechblock-ng
    df-youtube
    kagi-search
    darkreader
    auto-tab-discard
    browserpass
    privacy-badger
    ublock-origin
    tridactyl
  ];

  settings = {
    "app.update.auto" = true;
    "browser.startup.homepage" = "about:blank";
#"browser.startup.homepage" = "https://lobste.rs";
    "browser.search.region" = "US";
    "ui.systemUsesDarkTheme" = 1;
    "network.http.http3.enabled" = true;
    "dom.image-lazy-loading.enabled" = true;
    "network.prefetch-next" = false;
    "general.smoothScroll" = true;
    "media.autoplay.default" = 1;
    "browser.cache.disk.enable" = false;
    "broswer.cache.memory.enable" = true;
    "broswer.sessionstore.resume_from_crash" = false;
    "browser.search.countryCode" = "US";
    "browser.search.isUS" = true;
    "browser.ctrlTab.recentlyUsedOrder" = false;
    "browser.newtabpage.enabled" = false;
    "browser.bookmarks.showMobileBookmarks" = true;
    "browser.uidensity" = 1;
    "browser.urlbar.placeholderName" = "search for something";
    "browser.urlbar.update1" = true;
    "extensions.pocket.enable" = false;
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
  };
  in
  {
    home = {
      inherit userChrome settings extensions;
      id = 0;
    };

  };
}
