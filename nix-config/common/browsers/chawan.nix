{ inputs, pkgs, ... }:
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  programs.chawan = {
    # Only enable on Linux - use Homebrew on Darwin (avoids gdb/nim build)
    enable = !isDarwin;
    package = inputs.chawan-flake.packages.${pkgs.system}.default;
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

      # siteconf.medium = {
      #   host = "(.*\\.)?medium\\.com";
      #   styling = false;
      #   scripting = "app";
      # };
    };
  };
}
