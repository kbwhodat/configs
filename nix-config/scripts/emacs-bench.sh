#!/usr/bin/env bash
# emacs-bench.sh — measure emacs startup against spec budget.
# Exits non-zero if any target is missed.
#
# Targets (from docs/superpowers/specs/2026-05-13-emacs-redesign-design.md §7.1):
#   batch cold init     ≤ 0.35 s
#   GUI cold init       ≤ 1.5 s
#   emacsclient -c warm ≤ 0.10 s

set -u
EMACS=$(command -v emacs)
EMACSCLIENT=$(command -v emacsclient)

if [ -z "$EMACS" ] || [ -z "$EMACSCLIENT" ]; then
  echo "FAIL: emacs or emacsclient not on PATH" >&2
  exit 2
fi

median () { sort -n | awk 'BEGIN{c=0} {a[c++]=$0} END{print a[int(c/2)]}'; }

target_batch=0.35
target_gui=1.50
target_warm=0.10

fail=0
check () {  # check <label> <observed> <target>
  local label=$1 obs=$2 tgt=$3
  awk -v o="$obs" -v t="$tgt" -v lbl="$label" 'BEGIN {
    if (o+0 <= t+0) {
      printf "PASS  %-30s %.3fs (<= %.3fs)\n", lbl, o, t
      exit 0
    } else {
      printf "FAIL  %-30s %.3fs (> %.3fs)\n", lbl, o, t
      exit 1
    }
  }' || fail=1
}

echo "=== Batch cold init (5 runs, median) ==="
batch_median=$(
  for i in 1 2 3 4 5; do
    /usr/bin/time -p "$EMACS" --batch -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 \
      | awk '/^real/{print $2}'
  done | median
)
check "batch cold init" "$batch_median" "$target_batch"

echo
echo "=== GUI cold init (1 run, frame will flicker) ==="
gui_real=$(
  /usr/bin/time -p "$EMACS" -l ~/.emacs.d/init.el --eval '(kill-emacs)' 2>&1 \
    | awk '/^real/{print $2}'
)
check "GUI cold init" "$gui_real" "$target_gui"

echo
echo "=== emacsclient -c warm frame (5 runs, median) ==="
if "$EMACSCLIENT" -e 't' >/dev/null 2>&1; then
  warm_median=$(
    for i in 1 2 3 4 5; do
      /usr/bin/time -p "$EMACSCLIENT" -c -e '(delete-frame)' 2>&1 \
        | awk '/^real/{print $2}'
    done | median
  )
  check "emacsclient warm frame" "$warm_median" "$target_warm"
else
  echo "SKIP  emacsclient warm frame (daemon not running)"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "ALL TARGETS MET"
  exit 0
else
  echo "ONE OR MORE TARGETS MISSED"
  exit 1
fi
