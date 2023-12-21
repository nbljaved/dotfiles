;; ;; Initialize package sources
;; (require 'package)
;; (setq package-archives '(("org" . "https://orgmode.org/elpa/")
;;                          ("melpa" . "https://melpa.org/packages/")

;;                          ;;("melpa-stable" . "https://stable.melpa.org/packages/")
;;                          ;; org-contrib
;;                          ("gnu" . "https://elpa.gnu.org/packages/")
;;                          ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
;; ;; Guix
;; ;; (add-to-list 'load-path "~/.guix-profile/share/emacs/site-lisp/")
;; ;; (guix-emacs-autoload-packages)

;; (add-to-list 'load-path "~/.emacs.d/manual/")
;; ;;(add-to-list 'load-path "~/.emacs.d/straight/build/")
;; ;; Initializes the package infrastructure
;; ;; (package-initialize)
;; ;; to prevent package.el loading packages prior to their init-file loading.
(setq package-enable-at-startup nil)
;; ;; (setq package-enable-at-startup t)
