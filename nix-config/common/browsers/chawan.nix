{pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;

in
{
  programs.chawan = {
    enable = if isDarwin then true else true;
    settings = {
      buffer = {
        images = true;
        styling = true;
      };
      display = {
        image-mode = "sixel";
        color-mode = "monochrome";
      };
      siteconf.all = {
        host = ".*";          # regex: matches every site
        scripting = "app";     # enable JavaScript
        #cookie = "save";     # optional: keep cookies across runs
        referer-from = true;  # optional: send Referer when following links
      };
    };
  };
}
