{
  config,
  lib,
  pkgs,
  ...
}: let
cfg = config.programs.zen-browser;
in {
  options = {
    programs.zen-browser = {
      enable = lib.mkEnableOption "Zen Browser";

      package = lib.mkOption {
        type = with lib.types; nullOr package;
        default = pkgs.zen-browser-bin;
        defaultText = lib.literalExpression "pkgs.zen-browser-bin";
      };

    };
  };

  config = lib.mkIf cfg.enable {
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "zen-browser.desktop";
      "x-scheme-handler/https" = "zen-browser.desktop";
      "application/xhtml+xml" = "zen-browser.desktop";
      "text/html" = "zen-browser.desktop";
    };

    home.packages = lib.optional (cfg.package != null) cfg.package;

    home.file.".zen/profiles.ini".text = lib.generators.toINI {} {
      General = {
        StartWithLastProfile = 1;
        Version = 2;
      };

      Profile0 = {
        Name = "Default";
        Path = "default";
        IsRelative = 1;
        ZenAvatarPath = "chrome://browser/content/zen-avatars/avatar-32.svg";
        Default = 1;
      };
    };
    home.file.".zen/default/extensions" = {
      source = let
        env = pkgs.buildEnv {
          name = "zen-extensions";
          paths = with pkgs.nur.repos.rycee.firefox-addons; [
            ghostery
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
            clearurls
            istilldontcareaboutcookies
            youtube-shorts-block
          ];
        };
      in "${env}/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
      recursive = true;
      force = true;
    };
  };
}
