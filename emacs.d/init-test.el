;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))
;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s with %d garbage collections."
                     (format "%.2f seconds"
                             (float-time
                              (time-subtract after-init-time before-init-time)))
                     gcs-done)))

;; Initialize package sources
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
			 ;;("melpa-stable" . "https://stable.melpa.org/packages/")
			 ("org" . "https://orgmode.org/elpa/")
			 ("elpa" . "https://elpa.gnu.org/packages/")))
;; Guix
(add-to-list 'load-path "~/.guix-profile/share/emacs/site-lisp/")
(guix-emacs-autoload-packages)

;; Initializes the package infrastructure
(package-initialize)

;; If there are no archived package contents, refresh them
(unless package-archive-contents
  (package-refresh-contents))


;; Uncomment this to get a reading on packages that get loaded at startup
;;(setq use-package-verbose t)

;; use-package
;; This is only needed once, near the top of the file
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(require 'use-package)
(require 'use-package-ensure)
(setq use-package-always-ensure t)

(use-package auto-package-update
  :config
  (setq auto-package-update-delete-old-versions t)
  (setq auto-package-update-hide-results t)
  (auto-package-update-maybe))

;; Change the user-emacs-directory to keep unwanted things out of ~/.emacs.d
(setq user-emacs-directory (expand-file-name "~/.cache/emacs/")
      url-history-file (expand-file-name "url/history" user-emacs-directory))

;; Use no-littering to automatically set common paths to the new user-emacs-directory
(use-package no-littering)

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

(set-default-coding-systems 'utf-8)
(set-language-environment "UTF-8")

(server-start)

;; Emacs to fully redraw the display before it processes queued input events. 
(setq redisplay-dont-pause t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(set-face-attribute 'default nil :font "Fira Mono" :height 138)
;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil
                    :font "Fira Mono"
                    :weight 'light
                    :height 138)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil
                    ;; :font "Cantarell"
                    :font "DejaVu Sans Mono"
                    :height 138
                    :weight 'light)

(use-package unicode-fonts
  :config
  (unicode-fonts-setup))

(use-package emojify
  :config
  (global-emojify-mode))

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-bar-width 5)
  (setq doom-modeline--pdf-pages t))

(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)

  ;; Enable custom neotree theme (all-the-icons must be installed!)
  ;;(doom-themes-neotree-config)
  ;; or for treemacs users
  (setq doom-themes-treemacs-theme "doom-colors") ; use the colorful treemacs theme
  (doom-themes-treemacs-config)

  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))

(global-prettify-symbols-mode 1)

;; highlight current line
(global-hl-line-mode 1)

;; insert  "" () etc in pairs
(electric-pair-mode 1)

;; highlight matching parenthesis
(show-paren-mode 1)

;; selected text is overwritten by the text we type
(delete-selection-mode 1)

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
	 ("C-<" . mc/mark-previous-like-this)))

(use-package smartparens
  :config
  )

(use-package expand-region
  :bind (("C-=" . er/expand-region)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package olivetti
  :defer nil
  :hook ((org-mode . olivetti-mode)
         (Info-mode . olivetti-mode)
         (nov-mode . olivetti-mode))
  :config
  (setq-default olivetti-body-width 90))

(use-package eyebrowse
  :defer nil
  :bind (("M-\`". eyebrowse-switch-to-window-config-0)
         ("M-1". eyebrowse-switch-to-window-config-1)
         ("M-2". eyebrowse-switch-to-window-config-2)
         ("M-3". eyebrowse-switch-to-window-config-3)
         ("M-4". eyebrowse-switch-to-window-config-4)
         ("M-5". eyebrowse-switch-to-window-config-5)
         ("M-6". eyebrowse-switch-to-window-config-6)
         ("M-7". eyebrowse-switch-to-window-config-7)
         ("M-8". eyebrowse-switch-to-window-config-8)
         ("M-9". eyebrowse-switch-to-window-config-9))
  :config
  (setq eyebrowse-switch-back-and-forth t)
  (setq eyebrowse-wrap-around t)
  (setq eyebrowse-new-workspace t) ;; clean up and display the scratch buffer
  (eyebrowse-mode 1))

(use-package all-the-icons)

(use-package dashboard
  :config
  (dashboard-setup-startup-hook))

(use-package company
  :init
  (add-hook 'after-init-hook 'global-company-mode)
  :bind (
         :map company-active-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous)
         :map company-search-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous))
  :config
  (setq company-idle-delay 0))

(use-package company-quickhelp
  :config
  (company-quickhelp-mode 1))

(use-package helm
  :bind (("C-<return>" . helm-mini)
         ("C-x b" . helm-mini)
         ("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files) ;;  C-s to search in files
         ("M-y" . helm-show-kill-ring)
         ("C-c h" . helm-command-prefix)
         :map helm-map
         ("<tab>" . helm-execute-persistent-action )
         ("C-z" . helm-select-action))

  :config
  (setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
        helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
        helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
        helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
        helm-ff-file-name-history-use-recentf t
        helm-echo-input-in-header-line t)

  (setq helm-autoresize-max-height 0)
  (setq helm-autoresize-min-height 20)
  (helm-autoresize-mode 1)

  (setq helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match    t
        helm-locate-fuzzy-match     t
        helm-semantic-fuzzy-search  t
        helm-imenu-fuzzy-match      t)

  ;; helm-man-woman
  (add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)

  ;; helm-locate <prefix> l
  ;; helm-resume <prefix> b
  (helm-mode 1))

(use-package helm-descbinds
  :config
  (helm-descbinds-mode 1))

(use-package helm-company
  :bind (:map company-mode-map
              ("C-;" . helm-company)))

(use-package swiper
  :bind (("C-s" . swiper)))

(defalias 'yes-or-no-p 'y-or-n-p)

(winner-mode 1)


(setq recentf-max-saved-items 500)
(setq-default recentf-save-file "~/.emacs.d/recentf")
(recentf-mode 1)

;; Toggle automatic saving to file-visiting buffers off.
(auto-save-visited-mode -1)

(global-set-key (kbd "s-k") 'kill-this-buffer)
(global-set-key (kbd "s-K") 'kill-buffer-and-window)
(global-set-key (kbd "C-o") 'other-window)
(global-set-key (kbd "C-g") 'keyboard-escape-quit)
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;;(define-key input-decode-map [?\C-m] [C-m])

;; vterm
(global-set-key (kbd "s-<return>") 'eshell)

;; text scale
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C-_") 'text-scale-decrease)

;; Some additional code to resolve the command-mode on minibuffer-exit  hook problem for users of helm/ivy with xah-fly keys:
(use-package xah-fly-keys
  :defer 0.1
  :after parrot
  :init
  (setq xah-fly-use-control-key nil)
  :bind (("<menu>" . xah-fly-mode-toggle)
         :map xah-fly-command-map
         ("<menu>" . xah-fly-mode-toggle))
  :config
  (xah-fly-keys-set-layout "qwerty")

  (setq in-xah-command nil) 

  (defun nbl/xah-minibuffer-setup ()
    "See if in command mode or not when entering minibuffer"
    (if xah-fly-insert-state-q
        (setq in-xah-command nil)
      (setq in-xah-command t)))

  (defun nbl/xah-minibuffer-exit ()
    "Exit minibuffer into the mode with which you entered"
    (if in-xah-command
        (xah-fly-command-mode-activate)
      (xah-fly-insert-mode-activate)))

  (add-hook 'minibuffer-setup-hook 'nbl/xah-minibuffer-setup)

  (remove-hook 'minibuffer-exit-hook 'xah-fly-command-mode-activate)
  (add-hook 'minibuffer-exit-hook 'nbl/xah-minibuffer-exit)

  (add-hook 'xah-fly-command-mode-activate-hook #'parrot-start-animation)
  (add-hook 'xah-fly-insert-mode-activate-hook  #'parrot-stop-animation)
  (xah-fly-keys 1))

(use-package hydra)

(use-package fish-mode)

(use-package fish-completion
  :config
  ;; To enable fish completion in all Eshell and M-x shell buffers, add this to your Emacs configuration:
  (when (and (executable-find "fish")
             (require 'fish-completion nil t))
    (global-fish-completion-mode)))

;; allow dired to delete or copy dir
(setq dired-recursive-copies (quote always)) ; “always” means no asking
(setq dired-recursive-deletes (quote top)) ; “top” means ask once

;;Copy from one dired dir to the next dired dir shown in a split window
(setq dired-dwim-target t)

(use-package dired-recent
  :config
  (dired-recent-mode 1))

(use-package dired-open)

(use-package diredfl
  :config
  (diredfl-global-mode))

(use-package dired-filter
  :hook ((dired-mode . dired-filter-group-mode))
  :config
  (setq dired-filter-group-saved-groups '(("default"
                                           ("PDF"
                                            (extension . "pdf"))
                                           ("LaTeX"
                                            (extension "tex" "bib"))
                                           ("Org"
                                            (extension  "org" "org~"))
                                           ("Archives"
                                            (extension "zip" "rar" "gz" "bz2" "tar"))
                                           ("Media"
                                            (extension "ogg" "flv" "mpg" "avi" "mp4" "mp3"))))))

(use-package dired-narrow)

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package pdf-tools
  :init
  (pdf-tools-install)
  :bind (:map pdf-view-mode-map
              ("C-s" . isearch-forward)))

(use-package pdf-view-restore
  :after pdf-tools
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode))

(use-package telega)
(define-key global-map (kbd "C-c t") telega-prefix-map)

(use-package which-key
  :config
  (which-key-mode 1))

(use-package disk-usage)

(use-package trashed)
(setq delete-by-moving-to-trash t)

(use-package polymode)
;; (use-package poly-org
;; :hook (org-mode . poly-org-mode))

(use-package tree-sitter)
(use-package tree-sitter-langs)
(global-tree-sitter-mode 1)
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

(use-package session
  :config
)

(use-package real-auto-save
  :hook ((pdf-view-mode . real-auto-save-mode)
         (org-mode . real-auto-save-mode))
  :config
  (setq real-auto-save-interval 5))

(use-package nov
  ;;:hook (nov-mode . olivetti-mode)
  :config
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
  (setq nov-unzip-program "/usr/bin/unzip"))

(use-package parrot
  :config
  (setq parrot-num-rotations nil)
  (setq parrot-animation-frame-interval 0.030) ;; default 0.045
  (parrot-set-parrot-type 'thumbsup) 
  (parrot-mode 1))

(use-package nyan-mode
  :config
  (nyan-mode 1))

(use-package beacon
  :config
  (beacon-mode 1))

(setq inferior-lisp-program "/usr/bin/sbcl")

(use-package sly)

(use-package stumpwm-mode
  :config
  (setq stumpwm-shell-program "/usr/bin/stumpish"))

(use-package paredit
  :init
  (autoload 'enable-paredit-mode "paredit" "Turn on pseudo-structural editing of Lisp code." t)
  :hook ((emacs-lisp-mode . enable-paredit-mode)
         (scheme-mode . enable-paredit-mode)
         (lisp-mode . enable-paredit-mode)
         (lisp-interaction-mode . enable-paredit-mode)
         (slime-repl-mode . enable-paredit-mode)
         (racket-mode . enable-paredit-mode)
         (racket-repl-mode . enable-paredit-mode))
  :config
  (bind-keys :map paredit-mode-map
             ("{"   . paredit-open-curly)
             ("}"   . paredit-close-curly))
  (unless terminal-frame
    (bind-keys :map paredit-mode-map
               ("M-[" . paredit-wrap-square)
               ("M-{" . paredit-wrap-curly))))

(use-package clhs
  :config
  (autoload 'clhs-doc "clhs" "Get doc on ANSI CL" t)
  (define-key help-map "\C-l" 'clhs-doc)
  (custom-set-variables
   '(tags-apropos-additional-actions '(("Common Lisp" clhs-doc clhs-symbols)))))

(use-package julia-mode)

(use-package julia-repl
  :hook (julia-mode . julia-repl-mode))

(use-package geiser
  :config
  (setq geiser-active-implementations '(guile)))

(use-package geiser-guile
  :config
  (setq geiser-guile-binary "/home/nabeel/.guix-profile/bin/guile"))

;; (use-package geiser-racket)

(use-package racket-mode
  :mode ("\\.rkt\\'" . racket-mode)
  :config
  (add-hook 'racket-mode-hook      #'racket-unicode-input-method-enable)
  (add-hook 'racket-repl-mode-hook #'racket-unicode-input-method-enable) )

(use-package jupyter
  :config
  (setq jupyter-eval-use-overlays t))

(use-package org
  :ensure t
  :hook ((org-mode . variable-pitch-mode)
         (org-mode . org-indent-mode))
  :bind (("C-c l" . org-store-link)
         ("C-c a" . org-agenda)
         ("C-c c" . org-capture) 
         :map org-mode-map
              ("C-c C-'" . org-babel-demarcate-block))
  :config
  (setq org-confirm-babel-evaluate nil)
  (setq org-src-fontify-natively t)
  ;; download images if their link is provided in org link form
  (set org-display-remote-inline-images 'download))

;; active Babel languages
(org-babel-do-load-languages
 'org-babel-load-languages
 '((latex . t)
   (python . t)
   (lisp . t)
   (emacs-lisp . t)
   ;;(sh . t)
   (jupyter . t)))

(setq org-latex-compiler "xelatex")

(setq org-latex-pdf-process '("%latex -interaction nonstopmode -output-directory %o %f" "%latex -interaction nonstopmode -output-directory %o %f" "%latex -interaction nonstopmode -output-directory %o %f"))

;; (add-to-list 'org-latex-packages-alist
             ;; '("AUTO" "polyglossia" t ("xelatex" "lualatex")))

(unless (boundp 'org-latex-classes)
  (setq org-latex-classes nil))
(add-to-list 'org-latex-classes
             '("article"
               "\\documentclass{article}"
               ("\\section{%s}" . "\\section*{%s}")))

(setq org-preview-latex-default-process 'dvipng)
(setq org-format-latex-options (plist-put org-format-latex-options :scale 1.6))

(setq org-preview-latex-process-alist
      '((dvipng :programs
                ("latex" "dvipng")
                :description "dvi > png" :message "you need to install the programs: latex and dvipng." :image-input-type "dvi" :image-output-type "png" :image-size-adjust
                (1.0 . 1.0)
                :latex-compiler
                ("latex -interaction nonstopmode -output-directory %o %f")
                :image-converter
                ("dvipng -D %D -T tight -o %O %f"))
        (dvisvgm :programs
                 ("latex" "dvisvgm")
                 :description "dvi > svg" :message "you need to install the programs: latex and dvisvgm." :image-input-type "dvi" :image-output-type "svg" :image-size-adjust
                 (1.7 . 1.5)
                 :latex-compiler
                 ("latex -interaction nonstopmode -output-directory %o %f")
                 :image-converter
                 ("dvisvgm %f -n -b min -c %S -o %O"))
        (imagemagick :programs
                     ("latex" "convert")
                     :description "pdf > png" :message "you need to install the programs: latex and imagemagick." :image-input-type "pdf" :image-output-type "png" :image-size-adjust
                     (1.0 . 1.0)
                     :latex-compiler
                     ("pdflatex -interaction nonstopmode -output-directory %o %f")
                     :image-converter
                     ("convert -density %D -trim -antialias %f -quality 100 %O"))))

(use-package texfrag
  :config
  (setq-default texfrag-scale 0.7)
  (texfrag-global-mode 1))

(use-package tex
  :ensure auctex
  :config
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

(use-package org-ref)

(use-package company-math
  :config
  (setq company-tooltip-align-annotations t)
  (add-to-list 'company-backends 'company-math-symbols-unicode))

(use-package unicode-math-input)

(use-package xah-math-input
  :config
  (global-xah-math-input-mode 1))

(use-package org-roam
  :init
  (add-hook 'after-init-hook 'org-roam-mode)
  :config
  (setq org-roam-directory "/home/nabeel/org/org-roam"))

(use-package org-auto-tangle
  :hook (org-mode . org-auto-tangle-mode))

;; This is needed as of Org 9.2
(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src sh"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
(add-to-list 'org-structure-template-alist '("cl" . "src lisp"))
;;(add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("jl" . "src julia"))

(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-remove-leading-stars t))


;; Replace list hyphen with dot
;; (font-lock-add-keywords 'org-mode
;;                         '(("^ *\\([-]\\) "
;;                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

;; Increase the size of various headings
(set-face-attribute 'org-document-title nil :font "Fira Mono" :weight 'bold :height 1.3)
(dolist (face '((org-level-1 . 1.4)
                (org-level-2 . 1.3)
                (org-level-3 . 1.25)
                (org-level-4 . 1.2)
                (org-level-5 . 1.1)
                (org-level-6 . 1.1)
                (org-level-7 . 1.1)
                (org-level-8 . 1.1)))
  (set-face-attribute (car face) nil :font "Fira Mono" :weight 'medium :height (cdr face)))


;; (let* ((variable-tuple
;; 	  (cond ((x-list-fonts "ETBembo")         '(:font "ETBembo"))
;; 		((x-list-fonts "Source Sans Pro") '(:font "Source Sans Pro"))
;; 		((x-list-fonts "Lucida Grande")   '(:font "Lucida Grande"))
;; 		((x-list-fonts "Verdana")         '(:font "Verdana"))
;; 		((x-family-fonts "Sans Serif")    '(:family "Sans Serif"))
;; 		(nil (warn "Cannot find a Sans Serif Font.  Install Source Sans Pro."))))
;; 	 (base-font-color     (face-foreground 'default nil 'default))
;; 	 (headline           `(:inherit default :weight bold :foreground ,base-font-color)))

;;     (custom-theme-set-faces
;;      'user
;;      `(org-level-8 ((t (,@headline ,@variable-tuple))))
;;      `(org-level-7 ((t (,@headline ,@variable-tuple))))
;;      `(org-level-6 ((t (,@headline ,@variable-tuple))))
;;      `(org-level-5 ((t (,@headline ,@variable-tuple))))
;;      `(org-level-4 ((t (,@headline ,@variable-tuple :height 1.1))))
;;      `(org-level-3 ((t (,@headline ,@variable-tuple :height 1.25))))
;;      `(org-level-2 ((t (,@headline ,@variable-tuple :height 1.5))))
;;      `(org-level-1 ((t (,@headline ,@variable-tuple :height 1.75))))
;;      `(org-document-title ((t (,@headline ,@variable-tuple :height 2.0 :underline nil))))))

;; Make sure org-indent face is available
(require 'org-indent)

;; Ensure that anything that should be fixed-pitch in Org files appears that way
(set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
(set-face-attribute 'org-table nil  :inherit 'fixed-pitch)
(set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
(set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
(set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
(set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
(set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

;; Get rid of the background on column views
(set-face-attribute 'org-column nil :background nil)
(set-face-attribute 'org-column-title nil :background nil)

;; TODO: Others to consider
;; '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
;; '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;; '(org-property-value ((t (:inherit fixed-pitch))) t)
;; '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;; '(org-table ((t (:inherit fixed-pitch :foreground "#83a598"))))
;; '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
;; '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))

(use-package org-appear
  :hook (org-mode . org-appear-mode))

(use-package org-download
  :config
  ;; Drag-and-drop to `dired`
  (add-hook 'dired-mode-hook 'org-download-enable))

(use-package org-noter
  :after org
  :config
  (setq org-noter-always-create-frame nil
        org-noter-separate-notes-from-heading t
        org-noter-doc-property-in-notes t
        org-noter-auto-save-last-location t))
