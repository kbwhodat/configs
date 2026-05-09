;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or


;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
;; (package! some-package)

(package! persistent-scratch)
(package! consult)
(package! md-roam
          :recipe (:host github :repo "nobiot/md-roam" :files ("*.el")))
(package! doom-alabaster-theme 
          :recipe (:host github :repo "kbwhodat/doom-alabaster-theme"))
