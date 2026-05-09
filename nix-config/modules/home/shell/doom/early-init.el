;; ~/.emacs.d/early-init.el

;; minimal UI early
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil
      frame-inhibit-implied-resize t)   ;; don't resize during init

;; don't let package.el do anything (you use Nix/Home-Manager)
(setq package-enable-at-startup nil
      package-quickstart nil)

;; faster I/O & subprocess comms (LSP, ripgrep, etc.)
(setq read-process-output-max (* 4 1024 1024))  ;; 4MB

;; GC + file-name-handler suspensions during init
(defvar my/file-name-handler-alist-backup file-name-handler-alist)
(setq file-name-handler-alist nil
      gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist my/file-name-handler-alist-backup
                  gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; native-comp noise off (if available)
(when (boundp 'native-comp-async-report-warnings-errors)
  (setq native-comp-async-report-warnings-errors 'silent))

;; cheaper rendering defaults (GUI)
(setq bidi-inhibit-bpa t)                    ;; faster bidirectional text
(setq inhibit-compacting-font-caches t)      ;; speed font rendering on some systems

;; optional micro-optimizations
(setq idle-update-delay 0.5)                 ;; update UI less often during idle
