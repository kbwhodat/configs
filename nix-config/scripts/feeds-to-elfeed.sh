#!/usr/bin/env bash
# Convert nix-config/data/feeds.txt -> ~/.emacs.d/elfeed-feeds.el.
# Edit feeds.txt to add/remove sources, run this (or `darwin-rebuild
# switch') to regenerate, then in emacs: `M-: (load "~/.emacs.d/elfeed-feeds.el") RET'.
set -eu

REPO_ROOT="${REPO_ROOT:-$HOME/.config/nix-config}"
SOURCE="${1:-$REPO_ROOT/data/feeds.txt}"
OUT="${2:-$HOME/.emacs.d/elfeed-feeds.el}"

[ -r "$SOURCE" ] || { echo "error: $SOURCE not readable" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"

awk '
  BEGIN {
    print ";;; elfeed-feeds.el --- auto-generated from data/feeds.txt -*- lexical-binding: t; -*-"
    printf ";; Source:    %s\n", "'"$SOURCE"'"
    printf ";; Generated: "; system("date \"+%Y-%m-%d %H:%M\"")
    print  ";; DO NOT EDIT — edit data/feeds.txt and re-run scripts/feeds-to-elfeed.sh"
    print  ""
    print  "(setq elfeed-feeds"
    print  "      (quote ("
  }
  /^[[:space:]]*(#|$)/ { next }
  {
    url = $1
    printf "        (\"%s\"", url
    for (i = 2; i <= NF; i++) printf " %s", $i
    printf ")\n"
  }
  END { print "        )))" }
' "$SOURCE" > "$OUT"

count=$(grep -c '^        (' "$OUT")
echo "Wrote $count feeds to $OUT"
