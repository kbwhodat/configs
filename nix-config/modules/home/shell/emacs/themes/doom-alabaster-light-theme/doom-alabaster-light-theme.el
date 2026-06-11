;;; doom-alabaster-light-theme.el --- A light theme with little syntax highlighting -*- lexical-binding: t; no-byte-compile: t -*-
;;
;; Companion to kbwhodat's `doom-alabaster' (the dark fork).  This is a
;; port of tonsky's original Sublime Alabaster — the LIGHT scheme
;; alabaster started as.  Same minimal aesthetic: most code stays in
;; the default foreground, only strings / functions / comments /
;; constants / types pick up colour.  Designed to share an identity
;; with `doom-alabaster' so toggling between them feels like flipping
;; the page, not switching themes.
;;
;; Reference palette: https://github.com/tonsky/sublime-scheme-alabaster
;;
;;; Code:
(require 'doom-themes)

(defgroup doom-alabaster-light-theme nil
  "Options for the `doom-alabaster-light' theme."
  :group 'doom-themes)

(def-doom-theme doom-alabaster-light
  "A light theme with little highlighting (Sublime Alabaster port)."

;;;; Colors
  ;; name        default     256         16
  ((bg           '("#F7F7F7" "#F7F7F7"   "white"))
   (base0        '("#FFFFFF" "#FFFFFF"   "white"))
   (base1        '("#EAEAEA" "#EAEAEA"   "white"))
   (base2        '("#E0E0E0" "#E0E0E0"   "brightwhite"))
   (base3        '("#909090" "#909090"   "brightblack"))
   (base4        '("#D6D6D6" "#D6D6D6"   "brightwhite"))
   (base5        '("#A0A0A0" "#A0A0A0"   "brightblack"))
   (base6        '("#606060" "#606060"   "brightblack"))
   (base7        '("#303030" "#303030"   "black"))
   (base8        '("#000000" "#000000"   "black"))
   ;; Slightly off-black so `base8' (pure #000000) reads as more
   ;; emphatic for types/etc.  Visually indistinguishable from pure
   ;; black on most displays for body text, but enough of a delta for
   ;; bold types to read as "darker, not just heavier".
   (fg           '("#1c1c1c" "#1c1c1c"   "black"))
   (grey-light   '("#A0A0A0" "#A0A0A0"   "brightblack"))
   (grey-comment '("#AA3731" "#AA3731"   "red"))      ; alabaster signature: red comments
   (fg-alt       '("#444444" "#444444"   "black"))
   (bg-alt       base0)

   (grey       base3)

   (red          '("#AA3731" "#AA3731"   "red"))
   (green        '("#448C27" "#448C27"   "green"))
   (yellow       '("#7B5C19" "#7B5C19"   "yellow"))
   (dark-blue    '("#325CC0" "#325CC0"   "blue"))
   (magenta      '("#7A3E9D" "#7A3E9D"   "magenta"))
   (dark-cyan    '("#0F7B7B" "#0F7B7B"   "cyan"))
   (light-yellow '("#7B5C19" "#7B5C19"   "yellow"))
   (orange       '("#A14600" "#A14600"   "brightred"))
   (teal         '("#3A8A14" "#3A8A14"   "brightgreen"))
   (violet       '("#7A3E9D" "#7A3E9D"   "brightmagenta"))
   (cyan         '("#0F7B7B" "#0F7B7B"   "brightcyan"))
   (blue         '("#325CC0" "#325CC0"   "brightblue"))

   (yellow-highlight '("#F5E6A8" "#F5E6A8"   "yellow"))
   (bg-dark base2)

;;;; face categories -- required for all themes
   (highlight      blue)
   (vertical-bar   base2)
   (selection      dark-blue)
   (builtin        fg)
   (comments       grey-comment)
   (doc-comments   green)
   (constants      magenta)
   (functions      dark-blue)
   (keywords       fg)
   (methods        fg)
   (operators      fg)
   (type           dark-blue)
   (strings        green)
   (variables      fg)
   (numbers        magenta)
   (region         '("#D6ECF2" "#D6ECF2"   "brightcyan"))
   (error          red)
   (warning        orange)
   (success        green)
   (vc-modified    yellow)
   (vc-added       green)
   (vc-deleted     red)

   (modeline-fg fg-alt)
   (modeline-bg bg)
   (modeline-bg-inactive base1))

;;;; Base theme face overrides
  (;; Types: same color as regular code, just BOLD (Zed alabaster
   ;; style).  Matches the upstream dark `doom-alabaster' treatment so
   ;; toggling between the two keeps the same syntax-highlight
   ;; identity — distinction comes from weight, not hue.
   (font-lock-type-face              :foreground base8)
   (tree-sitter-hl-face:type.builtin :foreground base8)))

(provide-theme 'doom-alabaster-light)
;;; doom-alabaster-light-theme.el ends here
