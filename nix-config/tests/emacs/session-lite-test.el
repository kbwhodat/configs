;;; session-lite-test.el --- Tests for lightweight session restore -*- lexical-binding: t; -*-

(require 'ert)
(require 'cl-lib)

(defvar persp-mode nil)
(defvar *persp-hash* nil)

(add-to-list 'load-path
             (expand-file-name "../../modules/home/shell/emacs/lisp"
                               (file-name-directory (or load-file-name buffer-file-name))))

(require 'config-session-lite)

(defmacro my/session-lite-test-with-temp-files (bindings &rest body)
  "Bind BINDINGS to temporary files while running BODY."
  (declare (indent 1))
  `(let ,(mapcar (lambda (binding)
                   `(,(car binding) (make-temp-file ,(cadr binding))))
                 bindings)
     (unwind-protect
         (progn ,@body)
       ,@(mapcar (lambda (binding)
                   `(when (file-exists-p ,(car binding))
                      (delete-file ,(car binding))))
                 bindings))))

(ert-deftest my/session-lite-global-snapshot-uses-file-backed-mru-buffers ()
  (my/session-lite-test-with-temp-files ((first-file "session-lite-first")
                                         (second-file "session-lite-second"))
    (let ((first-buffer (find-file-noselect first-file))
          (second-buffer (find-file-noselect second-file))
          (scratch-buffer (get-buffer-create "*session-lite-test-scratch*")))
      (unwind-protect
          (progn
            (switch-to-buffer first-buffer)
            (switch-to-buffer scratch-buffer)
            (switch-to-buffer second-buffer)
            (let ((snapshot (my/session-lite-build-snapshot)))
              (should (equal (plist-get snapshot :version) 1))
              (should-not (plist-get snapshot :current-workspace))
              (should (equal (plist-get snapshot :selected-file) second-file))
              (should (equal (plist-get snapshot :global-files)
                             (list second-file first-file)))
              (should-not (plist-get snapshot :workspaces))))
        (mapc #'kill-buffer (list first-buffer second-buffer scratch-buffer))))))

(ert-deftest my/session-lite-filters-remote-and-large-files ()
  (my/session-lite-test-with-temp-files ((normal-file "session-lite-normal")
                                         (large-file "session-lite-large"))
    (with-temp-file large-file
      (insert (make-string 2048 ?x)))
    (let ((my/session-lite-max-file-size 1024)
          (normal-buffer (find-file-noselect normal-file))
          (large-buffer (find-file-noselect large-file))
          (remote-buffer (generate-new-buffer "session-lite-remote")))
      (unwind-protect
          (progn
            (with-current-buffer remote-buffer
              (setq buffer-file-name "/ssh:example:/tmp/remote.txt"))
            (switch-to-buffer remote-buffer)
            (switch-to-buffer large-buffer)
            (switch-to-buffer normal-buffer)
            (should (equal (plist-get (my/session-lite-build-snapshot) :global-files)
                           (list normal-file))))
        (mapc #'kill-buffer (list normal-buffer large-buffer remote-buffer))))))

(ert-deftest my/session-lite-snapshot-captures-persp-workspaces-when-present ()
  (my/session-lite-test-with-temp-files ((work-file "session-lite-work")
                                         (notes-file "session-lite-notes")
                                         (global-file "session-lite-global"))
    (let* ((work-buffer (find-file-noselect work-file))
           (notes-buffer (find-file-noselect notes-file))
           (global-buffer (find-file-noselect global-file))
           (work-persp (list :buffers (list work-buffer)))
           (notes-persp (list :buffers (list notes-buffer)))
           (*persp-hash* (make-hash-table :test 'equal))
           (persp-mode t))
      (puthash "work" work-persp *persp-hash*)
      (puthash "notes" notes-persp *persp-hash*)
      (unwind-protect
          (cl-letf (((symbol-function 'persp-names) (lambda () '("none" "work" "notes")))
                    ((symbol-function 'get-current-persp) (lambda () work-persp))
                    ((symbol-function 'safe-persp-name) (lambda (_persp) "work"))
                    ((symbol-function 'persp-buffers) (lambda (persp) (plist-get persp :buffers))))
            (switch-to-buffer global-buffer)
            (switch-to-buffer work-buffer)
            (let* ((snapshot (my/session-lite-build-snapshot))
                   (work (seq-find (lambda (workspace)
                                     (equal (plist-get workspace :name) "work"))
                                   (plist-get snapshot :workspaces)))
                   (notes (seq-find (lambda (workspace)
                                      (equal (plist-get workspace :name) "notes"))
                                    (plist-get snapshot :workspaces))))
              (should (equal (plist-get snapshot :current-workspace) "work"))
              (should (equal (plist-get snapshot :selected-file) work-file))
              (should (equal (plist-get snapshot :global-files)
                             (list work-file global-file notes-file)))
              (should (equal (plist-get work :files) (list work-file)))
              (should (equal (plist-get work :selected-file) work-file))
              (should (equal (plist-get notes :files) (list notes-file)))
              (should (equal (plist-get notes :selected-file) notes-file))))
        (mapc #'kill-buffer (list work-buffer notes-buffer global-buffer))))))

;;; session-lite-test.el ends here
