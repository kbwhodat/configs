{ pkgs, config, ... }:

{
  programs.password-store = {
    enable = true;
    package = pkgs.pass;
    settings = {
      PASSWORD_STORE_DIR = "${config.home.homeDirectory}/.password-store";
      PASSWORD_STORE_KEY = "06DF6AD45BCA8A10D7997CDC2261792609E5D095";
      PASSWORD_STORE_CLIP_TIME = "60";
      PASSWORD_STORE_GPG_OPTS = "--quiet --batch --yes --compress-algo=none --no-encrypt-to";
    };
  };
}
