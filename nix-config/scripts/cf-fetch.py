#!/usr/bin/env -S uv run --quiet --no-project --with curl_cffi>=0.7.4 --
"""Fetch URL with Chrome TLS-fingerprint impersonation; dump HTML to stdout.

Defeats Cloudflare's TLS-fingerprint check by performing a real Chrome
TLS handshake at the network layer.  No browser, no Docker — just a
curl variant linked against BoringSSL that produces a byte-for-byte
Chrome handshake.  Empirically clears CF on Medium / Substack / most
article-class sites that fall over for plain `url-retrieve`.

Fails on sites with Cloudflare Turnstile, Bot Fight Mode, or
JS-behavioral analysis (rare for article reading; common for
banking / forums).  For those, escalate to `chromium --headless
--dump-dom URL` or a WKWebView-based fetcher.

Usage:
  cf-fetch.py URL [impersonate-profile]

Default profile: chrome120.  Other profiles in this curl_cffi version:
chrome124, safari17_0.  Use `--list` to see all.
"""
import sys
from curl_cffi import requests


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        sys.stderr.write(__doc__)
        return 2
    if sys.argv[1] == "--list":
        from curl_cffi.requests import BrowserType
        for b in BrowserType.__members__:
            print(b)
        return 0

    url = sys.argv[1]
    profile = sys.argv[2] if len(sys.argv) > 2 else "chrome120"

    try:
        r = requests.get(url, impersonate=profile, timeout=30, allow_redirects=True)
    except Exception as e:
        sys.stderr.write(f"cf-fetch: {e}\n")
        return 1

    sys.stdout.write(r.text)
    return 0 if r.ok else 1


if __name__ == "__main__":
    sys.exit(main())
