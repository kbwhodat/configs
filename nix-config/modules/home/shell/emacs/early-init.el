;;; early-init.el --- Early initialization -*- lexical-binding: t; no-byte-compile: t -*-
;;; Commentary:
;; Runs before package.el / GUI / theme. Keep this MINIMAL.
;; Native-AOT and treesit grammars are already wired by the nix wrapper.
;;; Code:

;; --- minimal UI ---
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil
      frame-inhibit-implied-resize t)

;; --- package.el off (nix manages everything) ---
(setq package-enable-at-startup nil
      package-quickstart nil)

;; --- diagnostic: per-package load/config timings (OFF) ---
;; When enabled, every `use-package' form records start/end timestamps
;; for :init / :config so `M-x use-package-report' shows the slow
;; packages.  Useful when tuning startup — off otherwise to keep the
;; per-form overhead at zero.  Flip to `t' temporarily when investigating
;; a new slow package.
(setq use-package-compute-statistics nil)

;; --- suppress redisplay + minibuffer messages during startup ---
;; Saves the visual cost of repainting the unstyled frame + flashing
;; "Loading X..." messages during init.  Reset on `window-setup-hook'
;; (first frame paint).  Trade-off: init errors won't render visually
;; until window-setup fires — but they still go to *Messages*.
;;
;; Plain `setq' (not `setq-default'): we want the GLOBAL value flipped
;; for the init window, NOT a default that leaks into every new buffer
;; created before `window-setup-hook' fires (those buffers would
;; inherit `t' as their buffer-local default and render blank).
(setq inhibit-redisplay t
      inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq inhibit-redisplay nil
                  inhibit-message nil)
            (redisplay)))

;; --- subprocess I/O (eglot, ripgrep) ---
(setq read-process-output-max (* 4 1024 1024))

;; emacs 31+: cache load-path scans (no-op on <= 30).
(when (and (boundp 'load-path-filter-function)
           (fboundp 'load-path-filter-cache-directory-files))
  (setq load-path-filter-function #'load-path-filter-cache-directory-files))

;; --- GC + file-handler suspension during init ---
(defvar my/file-name-handler-alist-backup file-name-handler-alist)
(setq file-name-handler-alist nil
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist-backup
                  gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; --- native-comp warnings silent ---
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; --- native-comp tuning for runtime JIT compilation ---
;; Most of our packages are AOT-compiled by nix at build time, so these
;; flags only kick in for .el files loaded outside that scope. Cheap to
;; set, real effect on packages installed/loaded post-build.
;;
;; Only Apple Silicon gets `-mcpu=apple-m1'. Intel macs and Linux hosts
;; must not inherit ARM CPU flags.
(setq native-comp-speed 3
      native-comp-compiler-options
      '("-O2" "-g0" "-fno-omit-frame-pointer" "-fno-finite-math-only")
      native-comp-driver-options
      (cond
       ((and (eq system-type 'darwin)
             (string-match-p "^aarch64-" system-configuration))
        '("-Wl,-w" "-mcpu=apple-m1"))
       ((eq system-type 'darwin)
        '("-Wl,-w"))
       (t nil)))

;; --- cheap rendering defaults ---
;; NOTE: `idle-update-delay' is tuned in config-perf.el (0.1).  Don't set
;; it here too — last-write-wins, and we want the perf value to be the
;; canonical one.
(setq bidi-inhibit-bpa t
      inhibit-compacting-font-caches t
      frame-resize-pixelwise t)
;; Stronger than bidi-inhibit-bpa alone — disables full bidirectional
;; layout reordering. Acceptable cost on English/code content.
(setq-default bidi-display-reordering 'left-to-right
              bidi-paragraph-direction 'left-to-right)

;; --- skip xrdb / X11 resource processing on startup ---
;; No-op on macOS (Cocoa), but avoids a millisecond-scale stat() on Linux.
(setq inhibit-x-resources t)

;; --- skip case-insensitive second pass over auto-mode-alist ---
;; Saves a small chunk on every file open. Cost: lowercase-only ext
;; matching, which is what 99% of file names use.
(setq auto-mode-case-fold nil)

;; --- undecorated frames (macOS) ---
(add-to-list 'default-frame-alist '(undecorated . t))

;; --- sensible default size for emacsclient -c new frames ---
;; Without these, new frames open at emacs's built-in default of 80×24
;; chars — the tiny square you saw on EmacsClient launch.
;; ~140×45 chars ≈ 1100×850 px at 14pt mono.
(add-to-list 'default-frame-alist '(width  . 140))
(add-to-list 'default-frame-alist '(height . 45))

(provide 'early-init)
;;; early-init.el ends here
