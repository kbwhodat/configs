;;; config-freeze-watchdog.el --- TEMPORARY freeze diagnostics -*- lexical-binding: t; -*-
;;; Commentary:
;; TEMPORARY DIAGNOSTIC — REMOVE once the gopls first-open freeze is
;; root-caused.  Three probes, all cheap:
;;   1. A 0.5 s heartbeat timer.  Timers can't fire while the main
;;      thread is blocked, so a gap between ticks > 1.5 s = a UI freeze
;;      window, logged with timestamp + duration.
;;   2. Around-advice on `lsp-request' (the SYNCHRONOUS request path —
;;      the async one is `lsp-request-async'): logs any blocking LSP
;;      request > 0.3 s with its method name.
;;   3. Around-advice on `call-process': logs any synchronous
;;      subprocess > 0.3 s with the program name (catches direnv, vc,
;;      formatters, ...).
;; Read the evidence with `M-x my/freeze-report'.
;;; Code:

(defvar my/freeze-log nil
  "Accumulated freeze evidence, newest first.")

(defvar my/freeze--last-tick (float-time))
(defvar my/freeze--last-gcs gcs-done)
(defvar my/freeze--last-gc-sec gc-elapsed)

(defun my/freeze--log (fmt &rest args)
  (push (apply #'format (concat "[%s] " fmt)
               (format-time-string "%H:%M:%S") args)
        my/freeze-log))

;; Heartbeat logs GC activity inside each blocked window so a
;; garbage-collection pause is distinguishable from CPU/filter work.
(run-with-timer
 0.5 0.5
 (lambda ()
   (let ((now (float-time)))
     (when (> (- now my/freeze--last-tick) 1.5)
       (my/freeze--log "UI blocked ~%.1fs | GCs in window: %d taking %.2fs"
                       (- now my/freeze--last-tick)
                       (- gcs-done my/freeze--last-gcs)
                       (- gc-elapsed my/freeze--last-gc-sec)))
     (setq my/freeze--last-tick now
           my/freeze--last-gcs gcs-done
           my/freeze--last-gc-sec gc-elapsed))))

;; Raw wall-clock pipe waits that bypass `lsp-request'.
(advice-add 'accept-process-output :around
            (lambda (orig &rest args)
              (let ((t0 (float-time)))
                (prog1 (apply orig args)
                  (let ((dt (- (float-time) t0)))
                    (when (> dt 0.5)
                      (my/freeze--log "accept-process-output %.2fs on %S"
                                      dt (and (processp (car args))
                                              (process-name (car args)))))))))
            '((name . my/freeze-watchdog)))

;; Full-time CPU profiler so CPU-bound freezes get NAMED, not just
;; timed.  Slight memory overhead — acceptable for the duration of
;; this investigation.  `my/freeze-report' includes the profile.
(add-hook 'after-init-hook (lambda () (ignore-errors (profiler-start 'cpu))))

(with-eval-after-load 'lsp-mode
  (advice-add 'lsp-request :around
              (lambda (orig method &rest args)
                (let ((t0 (float-time)))
                  (prog1 (apply orig method args)
                    (let ((dt (- (float-time) t0)))
                      (when (> dt 0.3)
                        (my/freeze--log "SYNC lsp-request %s took %.2fs"
                                        method dt))))))
              '((name . my/freeze-watchdog))))

(advice-add 'call-process :around
            (lambda (orig program &rest args)
              (let ((t0 (float-time)))
                (prog1 (apply orig program args)
                  (let ((dt (- (float-time) t0)))
                    (when (> dt 0.3)
                      (my/freeze--log "call-process %s took %.2fs"
                                      program dt))))))
            '((name . my/freeze-watchdog)))

(defun my/freeze-report ()
  "Show the freeze watchdog log."
  (interactive)
  (if (null my/freeze-log)
      (message "freeze-watchdog: nothing logged yet")
    (with-current-buffer (get-buffer-create "*freeze-report*")
      (erase-buffer)
      (insert (mapconcat #'identity my/freeze-log "\n"))
      (goto-char (point-min))
      (pop-to-buffer (current-buffer)))))

(defun my/freeze-profile ()
  "Return the current CPU profile as a string (top entries expanded)."
  (when (and (fboundp 'profiler-cpu-running-p) (profiler-cpu-running-p))
    (profiler-stop))
  (profiler-report)
  (let ((buf (seq-find (lambda (b)
                         (string-match-p "CPU.*Profiler" (buffer-name b)))
                       (buffer-list))))
    (when buf
      (with-current-buffer buf
        (goto-char (point-min))
        (while (not (eobp))
          (ignore-errors (profiler-report-toggle-entry t))
          (forward-line 1))
        (prog1 (buffer-substring-no-properties (point-min) (point-max))
          (kill-buffer)
          (ignore-errors (profiler-start 'cpu)))))))

(provide 'config-freeze-watchdog)
;;; config-freeze-watchdog.el ends here
