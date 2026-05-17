{ inputs, pkgs, lib, ... }:
let
  inherit (pkgs.stdenv) isDarwin;

  # NOTE: hand-written TOML — `pkgs.formats.toml.generate` emits
  # `[siteconf.default-headers]` sub-tables for nested attrsets, which
  # chawan v0.4.0 crashes on with `IndexDefect` (verified by bisecting
  # the generated file).  Inline-table form
  # (`default-headers = { ... }`) parses correctly.  Generic TOML
  # writers don't produce inline tables, so we serialize the file
  # manually here.
  chawanConfig = ''
    [buffer]
    images = true
    styling = true
    user-style = """
    .container, .content, article, main, [role="main"], .post, .entry {
      max-width: 180ch !important;
      width: 100% !important;
    }
    """

    [display]
    image-mode = "sixel"
    color-mode = "monochrome"
    format-mode = ["bold", "italic", "underline"]

    [[siteconf]]
    host = ".*"
    scripting = "app"
    referer-from = true
    # Googlebot UA — Cloudflare and most paywall services whitelist
    # search-engine crawlers so sites get indexed.  Sending this UA
    # bypasses Cloudflare's "Checking your browser…" JS challenge AND
    # Medium / NYT / Substack-style paywalls.  This is exactly what
    # Reeder, NetNewsWire, Inoreader's full-text mode all do.  The
    # tradeoff: a few sites serve SEO-tweaked content to Googlebot
    # (usually cleaner, sometimes different).  For article-reading
    # via cha (newsboat browser + elfeed `C' binding) this is a win.
    default-headers = { User-Agent = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" }
  '';
in
{
  # Install chawan on Linux from the flake; darwin uses brew (avoids
  # the gdb/nim build).  `programs.chawan` is bypassed entirely — its
  # `settings` option goes through the same broken TOML writer.
  home.packages = lib.mkIf (!isDarwin) [
    inputs.chawan-flake.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Config delivered via home.file on both platforms.  Brew's `cha` on
  # darwin and the flake's `cha` on Linux both read this same path.
  home.file.".config/chawan/config.toml".text = chawanConfig;
}
