{pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
  
  # Import unstable nixpkgs
  unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    sha256 = "sha256:15bmq6yx1sjjhlwq4b6sqzdifnsghwvh22fg6szp57xf97xivh6h";
  }) {
    system = pkgs.system;
    config.allowUnfree = true;
  };

in
{
  programs.chawan = {
    enable = if isDarwin then true else true;
    package = unstable.chawan;
    settings = {
      buffer = {
        images = true;
        styling = true;
        user-style = ''
          .container, .content, article, main, [role="main"], .post, .entry {
            max-width: 180ch !important;
            width: 100% !important;
          }
        '';
      };
      display = {
        image-mode = "sixel";
        color-mode = "monochrome";
        format-mode = ["bold" "italic" "underline"];
      };
      siteconf.all = {
        host = ".*";          # regex: matches every site
        scripting = "app";     # enable JavaScript
        #cookie = "save";     # optional: keep cookies across runs
        referer-from = true;  # optional: send Referer when following links
        default-headers = {
          User-Agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36";
        };
      };
    };
  };
}
