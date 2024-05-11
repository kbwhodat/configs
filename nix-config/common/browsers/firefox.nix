{ config, pkgs, inputs,  ... }:

let
inherit (pkgs.stdenv) isDarwin;
fullName = "dns issue";

in
{
  programs.firefox.enable = true;
  programs.firefox.package =
    if isDarwin then
# Handled by the Homebrew module
# This populates a dummy package to satsify the requirement
      pkgs.runCommand "firefox-0.0.0" { } "mkdir $out"
    else
      pkgs.firefox;

  programs.firefox.profiles =
    let
    userChrome = builtins.readFile ../../../userChrome.css;

  extensions = with pkgs.nur.repos.rycee.firefox-addons; [
    browserpass
      betterttv
      consent-o-matic
      ublock-origin
      tridactyl
  ];

  settings = {
    "app.update.auto" = true;
    "browser.startup.homepage" = "about:blank";
#"browser.startup.homepage" = "https://lobste.rs";
    "browser.search.region" = "US";
    "browser.search.countryCode" = "US";
    "browser.search.isUS" = true;
    "browser.ctrlTab.recentlyUsedOrder" = false;
    "browser.newtabpage.enabled" = true;
    "browser.bookmarks.showMobileBookmarks" = true;
    "browser.uidensity" = 1;
    "browser.urlbar.placeholderName" = "Kagi";
    "browser.urlbar.update1" = true;
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
