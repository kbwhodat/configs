{ pkgs, config, ... }:

{
  progams.password-store = {
    enable = true;
    package = pkgs.pass;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}";
      PASSWORD_STORE_KEY = "BE5719EC9B943BC43E91FF24B6CFCBFF9D438A21";
      PASSWORD_STORE_CLIP_TIME = "60";
      PASSWORD_STORE_GPG_OPTS = "--quiet" "--yes" "--compress-algo=none" "--no-encrypt-to";
    };
  };
}
