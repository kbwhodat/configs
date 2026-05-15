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

;; --- subprocess I/O (eglot, ripgrep) ---
(setq read-process-output-max (* 4 1024 1024))

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
(setq bidi-inhibit-bpa t
      inhibit-compacting-font-caches t
      idle-update-delay 0.5
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
