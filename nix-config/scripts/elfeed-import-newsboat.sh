#!/usr/bin/env bash
# Convert newsboat urls → elfeed-feeds.el.  Skips comments, blank lines,
# and `"query:..."` newsboat saved-searches.  Newsboat's `"!"' tag
# (means "hidden") is stripped.
set -eu
URLS="${1:-$HOME/.config/newsboat/urls}"
OUT="${2:-$HOME/.emacs.d/elfeed-feeds.el}"

[ -r "$URLS" ] || { echo "error: $URLS not readable" >&2; exit 1; }

awk 'BEGIN { print ";;; elfeed-feeds.el --- auto-generated from newsboat urls -*- lexical-binding: t; -*-"
             printf ";; Source:    %s\n", "'"$URLS"'"
             printf ";; Generated: "; system("date \"+%Y-%m-%d %H:%M\"")
             print  ";; Re-run scripts/elfeed-import-newsboat.sh after editing newsboat urls."
             print  ""
             print  "(setq elfeed-feeds"
             print  "      (quote (" }
     /^[[:space:]]*#/   { next }
     /^[[:space:]]*$/   { next }
     /^"query:/         { next }
     {
       url = $1; gsub("\"", "", url)
       printf "        (\"%s\"", url
       for (i = 2; i <= NF; i++) {
         tag = $i; gsub("\"", "", tag)
         if (tag != "" && tag != "!") printf " %s", tag
       }
       printf ")\n"
     }
     END { print "        )))" }' "$URLS" > "$OUT"

count=$(grep -c '^        (' "$OUT")
echo "Wrote $count feeds to $OUT"
echo "In emacs: M-: (load \"$OUT\") RET   then SPC o f, then G to refresh"
