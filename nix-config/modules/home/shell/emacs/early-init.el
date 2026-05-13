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

;; --- cheap rendering defaults ---
(setq bidi-inhibit-bpa t
      inhibit-compacting-font-caches t
      idle-update-delay 0.5)

;; --- undecorated frames (macOS) ---
(add-to-list 'default-frame-alist '(undecorated . t))

;; --- benchmark-init must load FIRST to capture everything below ---
(require 'benchmark-init)
(add-hook 'after-init-hook #'benchmark-init/deactivate)

(provide 'early-init)
;;; early-init.el ends here
