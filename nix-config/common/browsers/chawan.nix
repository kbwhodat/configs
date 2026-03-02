{pkgs, ...}:
let
  inherit (pkgs.stdenv) isDarwin;
  
  # Import unstable nixpkgs for Linux (chawan 0.3.3)
  unstable = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz";
    sha256 = "sha256:00a3mfk96r00j26mnblm6rlimrfl35sjrq4zy94mpc5c2jqmx3i3";
  }) {
    system = pkgs.system;
    config.allowUnfree = true;
  };

in
{
  programs.chawan = {
    # Only enable on Linux - use Homebrew on Darwin (avoids gdb/nim build)
    enable = !isDarwin;
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
