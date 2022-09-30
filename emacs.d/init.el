(setq debug-on-error t)
(toggle-debug-on-error 1)
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

;; Bootstrap straight.el
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))


(setq straight-recipe-repositories '(melpa gnu-elpa-mirror el-get emacsmirror-mirror))
;; Use straight.el for use-package expressions
(straight-use-package 'use-package)
(use-package straight
  :custom (straight-use-package-by-default t))
;; Load the helper package for commands like `straight-x-clean-unused-repos'
;;(require 'straight-x)

;; do not byte-compile packages downloaded from package.el

;; Silence compiler warnings as they can be pretty disruptive
(setq comp-async-report-warnings-errors nil)
(setq warning-suppress-types '((comp) (:warning)))
;; (setq comp-deferred-compilation-deny-list (list "jupyter" "zmq"))
;; (setq native-comp-deferred-compilation-deny-list (list "jupyter" "zmq"))
;; (setq native-comp-bootstrap-deny-list (list "jupyter" "zmq"))

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
(setenv "LC_CTYPE" "en_US.UTF-8")

(setq initial-major-mode 'org-mode)

(server-start)

;; Emacs to fully redraw the display before it processes queued input events. 
(setq redisplay-dont-pause t)

(global-auto-revert-mode 1)
;; Also auto refresh dired, but be quiet about it
(setq global-auto-revert-non-file-buffers t)
(setq auto-revert-verbose nil)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(display-battery-mode 1)
;; time
(setq display-time-format "%H:%M")
(setq display-time-default-load-average nil)
(setq display-time-24hr-format t)
(display-time-mode -1)

(set-face-attribute 'default nil :font "Fira Code" :height 138)
;; Set the fixed pitch face
(set-face-attribute 'fixed-pitch nil
                    :font "Fira Code"
                    :weight 'regular
                    :height 140)

;; Set the variable pitch face
(set-face-attribute 'variable-pitch nil
                    ;; :font "Cantarell"
                    :font "DejaVu Sans Mono"
                    :height 140
                    :weight 'regular)

(use-package unicode-fonts
  :config
  (unicode-fonts-setup))

(use-package emojify
  :bind ("C-M-e" . emojify-insert-emoji)
  :config
  (setq-default company-emojify-emoji-styles '(unicode github))
  (global-emojify-mode))

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :config
  (setq doom-modeline-bar-width 5
        ;; small scroll-bar like in the bar 
        doom-modeline-hud t)
  (setq-default doom-modeline--pdf-pages t
                doom-modeline--debug-dap t)
  ;; to get eyerbowse window number in pdf-view mode (=workspace-name= segment)

  ;; 
  (doom-modeline-def-modeline 'pdf
    '(bar window-number workspace-name matches buffer-info pdf-pages)
    '(misc-info major-mode process vcs))
  (doom-modeline-def-modeline 'project
    '(bar window-number workspace-name matches buffer-info pdf-pages)
    '(misc-info major-mode process vcs))
  (doom-modeline-def-modeline 'dashboard
    '(bar window-number workspace-name matches buffer-info pdf-pages)
    '(misc-info major-mode process vcs)))

(use-package modus-themes
  :demand t
  :bind (("<f12>" . modus-themes-toggle))
  :config
  (setq modus-themes-bold-constructs t
        modus-themes-slanted-constructs t
        modus-themes-syntax '(alt-syntax)
        modus-themes-hl-line '(accented intense)
        modus-themes-intense-hl-line t
        modus-themes-links '(faint)
        modus-themes-paren-match '(bold intense)
        modus-themes-org-blocks 'gray-background
        modus-themes-region '(accented)
        modus-themes-variable-pitch-heading nil
        modus-themes-variable-pitch-ui nil
        modus-themes-mode-line nil
        modus-themes-completions '((matches . (extrabold intense))
                                   (selection . (extrabold intense))
                                   (popup . (extrabold intense))))

  (modus-themes-load-themes)
  (modus-themes-load-vivendi))

(with-eval-after-load 'org
  (setq org-src-block-faces
        '(("emacs-lisp" modus-themes-nuanced-magenta)
          ("elisp" modus-themes-nuanced-magenta)
          ("clojure" modus-themes-nuanced-magenta)
          ("clojurescript" modus-themes-nuanced-magenta)
          ;; lisp
          ("lisp" modus-themes-nuanced-magenta)
          ("c" modus-themes-nuanced-blue)
          ("c++" modus-themes-nuanced-blue)
          ("sh" modus-themes-nuanced-green)
          ("shell" modus-themes-nuanced-green)
          ("html" modus-themes-nuanced-yellow)
          ("xml" modus-themes-nuanced-yellow)
          ("css" modus-themes-nuanced-red)
          ("scss" modus-themes-nuanced-red)
          ("python" modus-themes-nuanced-green)
          ("ipython" modus-themes-nuanced-magenta)
          ("r" modus-themes-nuanced-cyan)
          ;; julia
          ("julia" modus-themes-nuanced-magenta)
          ("jupyter-julia" modus-themes-nuanced-magenta)
          ("yaml" modus-themes-nuanced-cyan)
          ("conf" modus-themes-nuanced-cyan)
          ;; ("docker" modus-themes-nuanced-cyan)
          )))

(global-prettify-symbols-mode 1)

(global-font-lock-mode 1)

;; highlight current line
;; lin-mode
;; https://protesilaos.com/emacs/lin
(global-hl-line-mode 1)
(use-package lin
  :config
  (lin-global-mode 1))

;; Spaces instead of tabs.
(setq-default indent-tabs-mode nil)

;; insert  "" () etc in pairs
(add-hook 'prog-mode-hook 'electric-pair-local-mode)
(add-hook 'prog-mode-hook 'linum-mode)

;;(electric-pair-mode -1)

;; highlight matching parenthesis
(show-paren-mode 1)

;; selected text is overwritten by the text we type
(delete-selection-mode 1)

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

(use-package smartparens
  :hook ((org-mode . smartparens-mode))
  :config
  (sp-local-pair 'org-mode "\\[" "\\]" :trigger "\\[")
  (sp-local-pair 'org-mode "\\(" "\\)" :trigger "\\(")
  (sp-local-pair 'org-mode "\\(" "\\)" :trigger "mm")
  )

(use-package expand-region
  :bind (("C-=" . er/expand-region)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package aggressive-indent
  :hook ((emacs-lisp-mode . aggressive-indent-mode)
         (scheme-mode . aggressive-indent-mode)
         ;; (lisp-mode . aggressive-indent-mode)
         ;; (lisp-interaction-mode . aggressive-indent-mode)
         (slime-repl-mode . aggressive-indent-mode)
         (racket-mode . aggressive-indent-mode)
         (racket-repl-mode . aggressive-indent-mode))
  :config)

(use-package olivetti
  :defer nil
  :hook ((org-mode . olivetti-mode)
         (Info-mode . olivetti-mode)
         (nov-mode . olivetti-mode))
  :config
  (setq-default olivetti-body-width 90))

(defun my-nov-font-setup ()
  (face-remap-add-relative 'variable-pitch :family "Alegreya"
                           :height 164))
(add-hook 'nov-mode-hook 'my-nov-font-setup)

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
         ("M-9". eyebrowse-switch-to-window-config-9)
         )
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
  ;; :init
  ;; (add-hook 'after-init-hook 'global-company-mode)
  :hook ((prog-mode . company-mode)
         (org-mode . company-mode)
         (text-mode . company-mode)
         (sly-mode . company-mode)
         (jupyter-repl-mode . company-mode))
  :bind (
         :map company-active-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous)
         :map company-search-map
         ("C-n" . company-select-next)
         ("C-p" . company-select-previous))
  :config
  ;; can still move cursor 
  (setq company-require-match nil)
  (setq company-idle-delay 0.1)
  (setq company-minimum-prefix-length 2))

(use-package company-quickhelp
  :hook ((company-mode . company-quickhelp-mode)))

(use-package helm
  :bind (("C-x b" . helm-mini)
         ("M-x" . helm-M-x)
         ("C-x C-f" . helm-find-files) ;;  C-s to search in files
         ("M-y" . helm-show-kill-ring)
         ("C-c h" . helm-command-prefix)
         :map helm-map
         ("<tab>" . helm-execute-persistent-action )
         ("C-z" . helm-select-action))

  :config
  (setq    helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
           helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
           helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
           helm-ff-file-name-history-use-recentf t
           helm-echo-input-in-header-line t)

  ;; (setq helm-display-function 'helm-display-buffer-in-own-frame
  ;; helm-display-buffer-reuse-frame t
  ;; helm-use-undecorated-frame-option t)

  (setq helm-input-idle-delay                     0.01
        helm-reuse-last-window-split-state        t
        helm-always-two-windows                   t
        helm-split-window-inside-p                t
        helm-commands-using-frame                 '(completion-at-point
                                                    helm-apropos
                                                    helm-eshell-prompts helm-imenu
                                                    helm-imenu-in-all-buffers)
        helm-actions-inherit-frame-settings       t
        helm-use-frame-when-more-than-two-windows t
        helm-use-frame-when-dedicated-window      nil
        helm-show-action-window-other-window      'left
        helm-allow-mouse                          t
        ;; C-n can move to next source.
        helm-move-to-line-cycle-in-source         nil
        helm-autoresize-max-height                60 ; it is %.
        helm-autoresize-min-height                20 ; it is %.
        helm-follow-mode-persistent               t
        helm-candidate-number-limit               500
        helm-visible-mark-prefix                  "✓")


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
  :after company
  :bind (:map company-mode-map
              ("C-'" . helm-company)))

(use-package helm-rg)

(use-package helm-dired-history
  :after dired
  :bind (:map dired-mode-map
              ("," . dired))
  :config
  (require 'savehist)
  (add-to-list 'savehist-additional-variables 'helm-dired-history-variable)
  (savehist-mode 1)

  (with-eval-after-load 'dired

    ;; if you are using ido,you'd better disable ido for dired
    ;; (define-key (cdr ido-minor-mode-map-entry) [remap dired] nil) ;in ido-setup-hook
    ))

(use-package swiper-helm
  :after helm
  :bind (("C-s" . swiper-helm)))

(defun nbl/+default/search-buffer ()
  "Conduct a text search on the current buffer.
If a selection is active, pre-fill the prompt with it."
  (interactive)
  (call-interactively
   (if (region-active-p)
       #'helm-swoop
     #'swiper-helm)))

(use-package helm-swoop
  :bind (("C-s" . nbl/+default/search-buffer))
  :config
  (setq helm-swoop-speed-or-color t ;; sacrifice colour for speed
        helm-swoop-use-fuzzy-match t
        ;; Save buffer when helm-multi-swoop-edit complete
        helm-multi-swoop-edit-save t
        ;; If this value is t, split window inside the current window
        helm-swoop-split-with-multiple-windows nil
        ;; Split direcion. 'split-window-vertically or 'split-window-horizontally
        helm-swoop-split-direction 'split-window-vertically
        ;; If nil, you can slightly boost invoke speed in exchange for text color
        helm-swoop-speed-or-color nil
        ;; ;; Go to the opposite side of line from the end or beginning of line
        helm-swoop-move-to-line-cycle t
        ;; Optional face for line numbers
        ;; Face name is `helm-swoop-line-number-face`
        helm-swoop-use-line-number-face t))

(use-package helm-icons
  :after (helm all-the-icons)
  :config
  (setq helm-icons-provider 'treemacs)
  (helm-icons-enable))

(use-package ace-jump-helm-line
  :bind (:map helm-map
              ("C-'" . ace-jump-helm-line))
  :config
  (setq ace-jump-helm-line-style 'post)
  (setq ace-jump-helm-line-idle-delay 0.5)
  ;; (ace-jump-helm-line-idle-exec-remove 'helm-mini)
  ;; (ace-jump-helm-line-idle-exec-add 'helm-company)

  ;; select
  (setq ace-jump-helm-line-default-action 'select)
  ;; (setq ace-jump-helm-line-select-key ?e)
  ;; Set the move-only and persistent keys
  (setq ace-jump-helm-line-move-only-key ?m)
  (setq ace-jump-helm-line-persistent-key ?p))

(defalias 'yes-or-no-p 'y-or-n-p)

(winner-mode 1)

;; Toggle automatic saving to file-visiting buffers off.
(auto-save-visited-mode -1)

(use-package flycheck
  :init
  (global-flycheck-mode 1))

(use-package flycheck-inline
  :after flycheck
  :hook ((flycheck-mode . flycheck-inline-mode)))

;; (use-package flycheck-pos-tip
;;   :after flycheck
;;   :init
;;   (flycheck-pos-tip-mode 1))

;; (use-package flycheck-pkg-config
;;   :after flycheck
;;   :config
;; )

(use-package yasnippet
  :demand t
  :config
  (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  (define-key yas-minor-mode-map (kbd "<tab>") yas-maybe-expand)
  (define-key yas-minor-mode-map (kbd "TAB") yas-maybe-expand)
  ;; Bind `SPC' to `yas-expand' when snippet expansion available (it
  ;; will still call `self-insert-command' otherwise).
  ;; (define-key yas-minor-mode-map (kbd "SPC") yas-maybe-expand)
  (add-hook 'yas-before-expand-snippet-hook (lambda () (smartparens-mode -1)))
  (add-hook 'yas-after-exit-snippet-hook (lambda () (smartparens-mode 1)))
  (yas-global-mode 1))

(use-package helm-c-yasnippet
  :after yasnippet
  :bind (("C-c y" . helm-yas-complete))
  :config
  (setq helm-yas-space-match-any-greedy t))

(use-package aas
  :hook (org-mode . aas-activate-for-major-mode)
  :config
  (aas-set-snippets 'org-mode
                    ";d" "$"
                    ;; set condition!
                    :cond #'org-inside-LaTeX-fragment-p
                    "fr" (lambda () (interactive)
                           (yas-expand-snippet "\\frac{$1}{$2} $0"))

                    "sum" (lambda () (interactive)
                            (yas-expand-snippet "\\sum_{$1}^{$2} $0"))))

(use-package laas
  :hook ((org-mode . laas-mode)
         (LaTeX-mode . laas-mode))
  :config )

(use-package undo-tree
  :config
  (global-undo-tree-mode 1))

(use-package avy
  :after org
  :bind (("C-;" . avy-goto-char-timer)
         ("C-c SPC" . avy-goto-char-2)
         ("M-g w" . avy-goto-word-1)
         ("M-g e" . avy-goto-word-0)
         ("M-g l" . avy-goto-line)
         :map org-mode-map
         ("C-c SPC" . avy-goto-char-2)
         ))

(use-package ace-isearch
  :config
  (global-ace-isearch-mode 1))

(global-set-key (kbd "C-`") 'delete-window)
(global-set-key (kbd "C-1") 'delete-other-windows)
(global-set-key (kbd "C-2") 'split-window-below)
(global-set-key (kbd "C-3") 'split-window-right)

(global-set-key (kbd "s-k") 'kill-this-buffer)
(global-set-key (kbd "s-K") 'kill-buffer-and-window)
(global-set-key (kbd "C-o") 'other-window)
(define-key prog-mode-map (kbd "C-o") 'other-window)
(require 'dired)
(define-key dired-mode-map (kbd "C-o") 'other-window)
;;(define-key compilation-mode-map (kbd "C-o") 'other-window)
(global-set-key (kbd "C-g") 'keyboard-escape-quit)
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;;(define-key input-decode-map [?\C-m] [C-m])

;; text scale
(global-set-key (kbd "C-+") 'text-scale-increase)
(global-set-key (kbd "C-_") 'text-scale-decrease)

;; move to current directory
(defun nbl/current-directory () (interactive)
       (dired "./"))
(global-set-key (kbd "<f4>") 'nbl/current-directory)
(define-key dired-mode-map (kbd "<f4>") #'dired-up-directory)
(define-key dired-mode-map (kbd "l") #'dired-up-directory)

(use-package general
  :demand t
  :config
  (general-auto-unbind-keys 1))

(use-package frog-jump-buffer
  :after all-the-icons
  :bind (("C-x C-b" . frog-jump-buffer))
  :config
  (setq frog-jump-buffer-use-all-the-icons-ivy t))

;; Some additional code to resolve the command-mode on minibuffer-exit  hook problem for users of helm/ivy with xah-fly keys:
(use-package xah-fly-keys
  :defer 0.1
  :init
  (setq xah-fly-use-control-key nil)
  (setq  xah-fly-use-meta-key nil )
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

  (defun nbl/xah-mode-on ()
    (set-cursor-color "#00ff00"))
  (defun nbl/xah-mode-off ()
    (set-cursor-color "#00bfff"))

  (add-hook 'xah-fly-command-mode-activate-hook 'nbl/xah-mode-on)
  (add-hook 'xah-fly-insert-mode-activate-hook  'nbl/xah-mode-off)
  (xah-fly-keys 1)
  (xah-fly-insert-mode-activate)
  (setq-default cursor-type 'box) ;; to override xah cursor stuff 
  )

(use-package hydra
  :ensure t)

(require 'term)

(define-key term-mode-map (kbd "C-o") 'other-window)
(define-key term-raw-map (kbd "C-o") 'other-window)

(use-package vterm
  :bind (("C-<return>" . vterm-other-window)
	 ("C-o" . 'other-window))
  :config
  (setq vterm-shell "/bin/zsh"
        vterm-kill-buffer-on-exit t
        vterm-term-environment-variable "eterm-256color"
        vterm-disable-bold t
        vterm-timer-delay nil
        ))

(use-package vterm-toggle
  :bind (;;("s-<return>" . vterm-toggle-cd)
         :map vterm-mode-map
         ("C-o" . other-window)))

;; (use-package multi-vterm
;;   ::bind (("s-<return>" . multi-vterm)
;;           :map vterm-mode-map
;;           ("C-o" . other-window)))

(use-package eshell-syntax-highlighting
  :after eshell-mode
  :config
  ;; Enable in all Eshell buffers.
  (eshell-syntax-highlighting-global-mode +1))

(use-package eshell-vterm
  :load-path "site-lisp/eshell-vterm"
  :after eshell vterm
  :config
  (eshell-vterm-mode))

(defalias 'eshell/v 'eshell-exec-visual)

(use-package fish-mode)

(use-package fish-completion
  :hook ((eshell-mode . fish-completion-mode)
         (shell-mode . fish-completion-mode))
  :config
  ;; To enable fish completion in all Eshell and M-x shell buffers, add this to your Emacs configuration:
  ;; (when (and (executable-find "fish")
  ;;            (require 'fish-completion nil t))
  ;;   (global-fish-completion-mode))
  )

(use-package eterm-256color
  :hook ((term-mode . eterm-256color-mode)
         (vterm-mode . eterm-256color-mode))
  :config
  (setq eterm-256color-disable-bold t
                                        ;eterm-256color-bright-blue "#00bfff"
        ))

(setq dired-dwim-target t ;Copy from one dired dir to the next dired dir shown in a split window
      dired-recursive-copies 'always
      dired-recursive-deletes 'always)

(define-key dired-mode-map (kbd "R") 'dired-async-do-rename)
(define-key dired-mode-map (kbd "C") 'dired-async-do-copy)

(use-package dired-hacks-utils
  :after dired
  :hook ((dired-mode . dired-utils-format-information-line-mode))
  :bind)

(use-package dired-ranger
  :bind (:map dired-mode-map
              ("M-w" . dired-ranger-copy)
              ("C-y" . dired-ranger-paste)
              ("C-u C-y" . dired-ranger-move)))

(use-package dired-recent
  :config
  (dired-recent-mode 1))

(use-package dired-open
  :bind (:map dired-mode-map
              ("J" . dired-open-xdg)))

(use-package dired-filter
  :hook ((dired-mode . dired-filter-group-mode))
  :bind (:map dired-filter-group-mode-map
              ("<tab>" . nil)
              ("<backtab>" . nil))
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
                                            (extension "ogg" "flv" "mpg" "avi" "mp4" "mp3" "jpg" "jpeg" "png"))
                                           ("epub"
                                            (extension "epub"))
                                           ("Spreadsheet"
                                            (extension "csv"))))))

(use-package dired-narrow)

(use-package diredfl
  :config
  (diredfl-global-mode))

(use-package all-the-icons-dired
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package dired-subtree
  :bind (:map dired-mode-map
              ("<tab>" . dired-subtree-toggle)
              ("<backtab>" . dired-subtree-cycle))
  :config
  (setq dired-subtree-overlays t))

(use-package pdf-tools
  ;; :straight nil
  :bind (:map pdf-view-mode-map
              ("C-s" . isearch-forward))
  :config)

(pdf-tools-install t)

(use-package pdf-view-restore
  :after pdf-tools
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode))

(use-package telega
  :config
  )

(use-package which-key
  :config
  (which-key-mode 1))

(use-package disk-usage)

(use-package trashed)
(setq delete-by-moving-to-trash t)

(use-package docker
  :ensure t
  :bind (("C-c d" . docker)))

(use-package docker-tramp
  :ensure t)

(use-package docker-compose-mode)

(use-package dockerfile-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))

(use-package tree-sitter)
(use-package tree-sitter-langs)
(global-tree-sitter-mode 1)
(add-hook 'tree-sitter-after-on-hook #'tree-sitter-hl-mode)

(use-package dogears
  :bind (:map global-map
              ("M-g d" . dogears-go)
              ("M-g M-b" . dogears-back)
              ("M-g M-f" . dogears-forward)
              ("M-g M-d" . dogears-list)
              ("M-g M-D" . dogears-sidebar))
  :hook ((prog-mode . dogears-mode)
         (org-mode . dogears-mode)))

(use-package session
  :config
  )

(use-package real-auto-save
  :hook ((pdf-view-mode . real-auto-save-mode)
         (org-mode . real-auto-save-mode))
  :config
  (setq real-auto-save-interval 5))

(use-package ini-mode
  :mode ("\\.ini\\'" . ini-mode))

(use-package smart-compile
  :bind (:map prog-mode-map
              ("<f5>" . smart-compile))
  :config
  (add-to-list 'smart-compile-alist
               '("\\.[Cc]+[Pp]*\\'" . "g++ -g -Wall  %f -o %n")))

(require 'eww)
(setq browse-url-browser-function 'eww-browse-url
      shr-use-colors nil
      shr-use-fonts nil)


(when (fboundp 'eww)
  (defun xah-rename-eww-buffer ()
    "Rename `eww-mode' buffer so sites open in new page.
URL `http://ergoemacs.org/emacs/emacs_eww_web_browser.html'
Version 2017-11-10"
    (let (($title (plist-get eww-data :title)))
      (when (eq major-mode 'eww-mode )
        (if $title
            (rename-buffer (concat "eww " $title ) t)
          (rename-buffer "eww" t)))))

  (add-hook 'eww-after-render-hook 'xah-rename-eww-buffer))

(use-package magit
  :ensure t
  :bind (:map magit-mode-map
              ("M-1" . nil)
              ("M-2" . nil)
              ("M-3" . nil)
              ("M-4" . nil)))

(use-package magit-todos
  :config
  (setq magit-todos-fontify-org nil
        magit-todos-group-by '(magit-todos-item-filename magit-todos-item-keyword)))

(use-package forge
  :after magit
  :config
  (setq  forge-topic-list-limit '(100 . -10)))

(use-package git-link)

(use-package topsy
  :hook (prog-mode . topsy-mode))

(use-package emacs-everywhere)

(use-package json-mode)

(use-package json-navigator)

(use-package restclient
  :mode (("\\.http\\'" . restclient-mode))
  :bind (:map restclient-mode-map
	      ("C-c C-f" . json-mode-beautify)))

(use-package ob-restclient
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((restclient . t))))

;; This package allows adding virtual comments to files in buffers.
;; These comments don’t belong to the files so they don’t.
;; They are saved in project root or a global file which can be viewed and searched.
;; The file name is .evc.
(use-package virtual-comment)

(use-package go-translate
  :config
  (setq gts-translate-list '(("en" "th") ("en" "ko") ("en" "ru"))))

(defun nbl/org-toggle-inline-images () (interactive)
       (org-toggle-inline-images 1))

(add-to-list 'tramp-connection-properties
             (list (regexp-quote "/sshx:user@host:")
                   "remote-shell" "/usr/bin/zsh"))

(use-package ssh-config-mode)

(setq auth-sources '("~/.authinfo"))

(use-package ledger-mode)

(use-package devdocs
  :bind (("C-h D" . devdocs-lookup))
  :config
  (add-hook 'java-mode-hook
            (lambda () (setq-local devdocs-current-docs '("openjdk~18")))))

(use-package nov
  ;;:hook (nov-mode . olivetti-mode)
  :config
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
  (setq nov-unzip-program "/usr/bin/unzip")
  )

(use-package mlscroll
  :config
  ;; truncate which-func, for default mode-line-format's
  (setq mlscroll-shortfun-min-width nil)
  (setq mlscroll-right-align nil
        mlscroll-alter-percent-position 'replace)
  (mlscroll-mode 1))

(use-package beacon
  :config
  (beacon-mode 1))

(use-package info-colors
  :commands (info-colors-fontify-node))

(add-hook 'Info-selection-hook 'info-colors-fontify-node)

(use-package eglot
  :ensure t
  :bind (("C-c h" . eldoc)
         ("C-c r" . eglot-rename))
  :config
  (setq eglot-connect-timeout 30
        eglot-extend-to-xref t))

(use-package ninja-mode)

(setq inferior-lisp-program "ros -Q run -- --dynamic-space-size 32000 --control-stack-size 4096")
(setq max-lisp-eval-depth 8000)

;; .mlisp
(add-to-list 'auto-mode-alist '("\\.mlisp\\'" . lisp-mode))

(use-package sly
  :straight (sly
             :type git
             :host github
             :repo "svetlyak40wt/sly"
             :branch "patches")
  :hook ((sly-mode . rainbow-delimiters-mode)
         (sly-mrepl-mode . lispy-mode))
  :bind (;; ("C-c C-d C-l" . sly-quickload)
         :map sly-mode-map
         ("C-r" . comint-history-isearch-backward-regexp))
  :config
  (setq slynk-stickers:*break-on-stickers* '(:before :after)
        sly-net-coding-system 'utf-8-unix
        sly-common-lisp-style-default 'sbcl)
  (setq sly-lisp-implementations
        '((sbcl ("ros" "-Q" "run" "--" "--dynamic-space-size" "32000" "--control-stack-size" "4096"))
          (lispworks ("ros" "-Q" "-L" "lispworks" "run"))))

  (setq sly-default-lisp 'sbcl))


;; (setq inferior-lisp-program nil)
;; (setq inferior-lisp-program "ros -Q run -- --dynamic-space-size 32000 --control-stack-size 4096")

;; log4cl
;; To change the ROOT category from Emacs, you can use Log4CL dropdown submenu, or Emacs command log4slime-level-selection which is bound to C-c C-g by default.
;;(load "~/.roswell/lisp/quicklisp/log4sly-setup.el")
;;(global-log4sly-mode 1)

(use-package sly-repl-ansi-color
  :config
  (push 'sly-repl-ansi-color sly-contribs ))

(use-package sly-quicklisp)

(use-package sly-asdf)

(use-package sly-macrostep)

(use-package sly-named-readtables)

(use-package lispy
  :hook ((emacs-lisp-mode . lispy-mode)
         (scheme-mode . lispy-mode)
         (lisp-mode . lispy-mode)
         (lisp-interaction-mode . lispy-mode)
         (slime-repl-mode . lispy-mode)
         (sly-mrepl-mode . lispy-mode)
         (racket-mode . lispy-mode)
         (racket-repl-mode . lispy-mode))
  :bind (:map lispy-mode-map
              ("M-." . nil)
              ("E" . lispy-eval-and-comment))
  :config
  ;; no space when pressing :
  (setq lispy-colon-p nil)
  (define-key lispy-mode-map (kbd "SPC") #'lispy-space))

(use-package clhs
  :config
  (autoload 'clhs-doc "clhs" "Get doc on ANSI CL" t)
  (define-key help-map "\C-l" 'clhs-doc)
  (custom-set-variables
   '(tags-apropos-additional-actions '(("Common Lisp" clhs-doc clhs-symbols)))))

;; CLHS is installed in this directory
;;   /home/nabeel/.roswell/lisp/quicklisp/dists/quicklisp/software/
;; Use C-c C-d h make-instance RET to test if the change was successful.
;; If it was, then this will open your browser and the URL will begin with "file:///".
(load "/home/nabeel/.roswell/lisp/quicklisp/clhs-use-local.el" t)
;; If the default browser used is not the one you wanted, here's how
;; you might tell Emacs to use Firefox instead:

;; (setq browse-url-firefox-program "firefox")

;; Or Google Chrome:

;; (setq browse-url-browser-function 'browse-url-generic)
;; (setq browse-url-generic-program "google-chrome")

(load "antlr-mode" t)
(add-to-list 'auto-mode-alist '("\\.g4\\'" . antlr-v4-mode))

(use-package mvn)
;; The basic operation is to invoke M-x mvn, which will ask you for a goal.

;; M-x mvn-last will re-issue the last command
;; M-x mvn-compile will run the standard mvn compile
;; M-x mvn-clean will run the standard mvn clean
;; M-x mvn-test will run the standard mvn test

(use-package maven-test-mode)

;; toggle back and forth between a test and it's class (bound to \C-c ,t)

;; verify the test class associated with the current buffer (bound to \C-c ,v)

;; verify the test defined in the current buffer if it is a test file (bound to \C-c ,v)

;; verify the test method defined at the point of the current buffer (bound to \C-c ,s)

;; re-run the last verification process (bound to \C-c ,r)

;; run tests for entire project (bound to \C-c ,a)

(use-package meghanada
  :hook ((java-mode . meghanada-mode))
  :config
  )

(use-package cperl-mode
  :config
;;; cperl-mode is preferred to perl-mode
;;; "Brevity is the soul of wit" <foo at acm.org>
  (defalias 'perl-mode 'cperl-mode)
  (setq cperl-hairy t))

(use-package company-plsense
  :config
  (add-to-list 'company-backends 'company-plsense)
  (add-hook 'perl-mode-hook 'company-mode)
  (add-hook 'cperl-mode-hook 'company-mode))

(use-package helm-perldoc)

(add-to-list 'load-path "~/.emacs.d/manual/emacs-pde/lisp/")
(load "pde-load" t)

(use-package ffap-perl-module)

(use-package man-completion)

(use-package python
  :mode ("[./]flake8\\'" . conf-mode)
  :mode ("/Pipfile\\'" . conf-mode)
  :config
  )

(add-to-list 'exec-path "/home/nabeel/.local/bin")
(require 'eglot nil t)
;; (add-hook 'python-mode-hook 'eglot-ensure)
;; (add-to-list 'eglot-server-programs '(foo-mode . ("foo-language-server" "--args")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))

;; Keybinding 	Description
;; C-M-i 	anaconda-mode-complete
;; M-. 	anaconda-mode-find-definitions
;; C-x 4 . 	anaconda-mode-find-definitions-other-window
;; C-x 5 . 	anaconda-mode-find-definitions-other-frame
;; M-= 	anaconda-mode-find-assignments
;; C-x 4 = 	anaconda-mode-find-assignments-other-window
;; C-x 5 = 	anaconda-mode-find-assignments-other-frame
;; M-r 	anaconda-mode-find-references
;; C-x 4 r 	anaconda-mode-find-references-other-window
;; C-x 5 r 	anaconda-mode-find-references-other-frame
;; M-, 	xref-pop-marker-stack
;; M-? 	anaconda-mode-show-doc

(use-package anaconda-mode
  :hook ((python-mode . anaconda-mode)
         (python-mode . anaconda-eldoc-mode))
  :bind (("C-c C-d" . anaconda-mode-show-doc)))

(use-package company-anaconda
  :config
  (eval-after-load "company"
    '(add-to-list 'company-backends 'company-anaconda)))

(use-package lpy
  :hook ((python-mode . lpy-mode))
  :bind (:map lpy-mode-map
              ("M-." . nil)
              ("E" . lispy-eval-and-comment)))

(use-package pyimport)

(use-package py-isort)
;; py-isort-buffer
;; py-isort-region

(use-package python-pytest)

(use-package pyvenv)

(use-package pipenv
  :hook (python-mode . pipenv-mode)
  :init
  (setq
   pipenv-projectile-after-switch-function
   #'pipenv-projectile-after-switch-extended))

(use-package pyenv-mode)

(require 'pyenv-mode)

(defun projectile-pyenv-mode-set ()
  "Set pyenv version matching project name."
  (let ((project (projectile-project-name)))
    (if (member project (pyenv-mode-versions))
        (pyenv-mode-set project)
      (pyenv-mode-unset))))

(add-hook 'projectile-after-switch-project-hook 'projectile-pyenv-mode-set)

(use-package live-py-mode)

;; To use it call M-x pippel-list-packages.

;; Shortcuts for pippel-package-menu-mode buffers:

;; m pippel-menu-mark-unmark remove mark
;; d pippel-menu-mark-delete mark for deletion
;; U pippel-menu-mark-all-upgrades mark all upgradable
;; u pippel-menu-mark-upgrade mark for upgrade
;; r pippel-list-packages refresh package list
;; i pippel-install-package prompt user for packages
;; x pippel-menu-execute perform marked package menu actions
;; RET pippel-menu-visit-homepage follow link

(use-package pippel)

(use-package yapfify
  :hook ((python-mode . yapf-mode)))

(use-package python-cell)

(use-package org
  :hook ((org-mode . variable-pitch-mode)
         (org-mode . org-indent-mode))
  :bind (("C-c l" . org-store-link)
	 ("C-c a" . org-agenda)
	 ("C-c c" . org-capture)
	 :map org-mode-map
	 ("C-c C-'" . org-babel-demarcate-block)
	 ("C-<print>" . org-screenshot-take)
	 ("C-c C-x C-v" . nbl/org-toggle-inline-images))
  :config
  (setq org-confirm-babel-evaluate nil)
  (setq org-src-fontify-natively t
	org-hide-emphasis-markers t
	org-return-follows-link t
	org-export-dispatch-use-expert-ui t
	;; prettify
	org-use-sub-superscripts "{}"
	org-edit-src-content-indentation 0
        org-use-speed-commands t
	)
  ;; download images if their link is provided in org link form
  (set org-display-remote-inline-images 'download))

;; C-c C-c also refreshes org-inline-image

(defun shk-fix-inline-images ()
  (when org-inline-image-overlays
    (org-redisplay-inline-images)))

;; https://emacs.stackexchange.com/questions/44664/apply-ansi-color-escape-sequences-for-org-babel-results
(defun ek/babel-ansi ()
  (when-let ((beg (org-babel-where-is-src-block-result nil nil)))
    (save-excursion
      (goto-char beg)
      (when (looking-at org-babel-result-regexp)
	(let ((end (org-babel-result-end))
	      (ansi-color-context-region nil))
	  (ansi-color-apply-on-region beg end))))))

(with-eval-after-load 'org
  (add-hook 'org-babel-after-execute-hook 'ek/babel-ansi)
  (add-hook 'org-babel-after-execute-hook 'org-redisplay-inline-images))

;; active Babel languages
(org-babel-do-load-languages
 'org-babel-load-languages
 '((latex . t)
   (python . t)
   (java . t)
   (C . t)
   (lisp . t)
   (emacs-lisp . t)
   (octave . t)
   (maxima . t)
   ;;(racket . t)
   (shell . t)
   ;;(julia . t)
   ;; (julia-vterm . t)
   ;;(ein . t)
   ;;(jupyter . t)
   ))

(setq org-babel-lisp-eval-fn 'sly-eval)

;; This is needed as of Org 9.2
(require 'org-tempo)

(add-to-list 'org-structure-template-alist '("sh" . "src sh"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
(add-to-list 'org-structure-template-alist '("cl" . "src lisp"))
(add-to-list 'org-structure-template-alist '("cp" . "src C++ :results output"))
(add-to-list 'org-structure-template-alist '("oc" . "src octave :results output"))
;;(add-to-list 'org-structure-template-alist '("ts" . "src typescript"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("jl" . "src julia"))
(add-to-list 'org-structure-template-alist '("ll" . "src lisp"))
(add-to-list 'org-structure-template-alist '("ej" . "src ein-julia :results output"))
(add-to-list 'org-structure-template-alist '("jj" . "src jupyter-julia"))

(setq org-babel-default-header-args:jupyter-julia
      '((:async . "yes")
        (:session . "jl")
        (:kernel . "julia-1.6")
        ;;(:display . "text/plain  text/org text/html text/markdown text/latex image/svg+xml image/png image/jpeg ")
        ))
(setq org-babel-default-header-args:C++
      '((:namespaces . "std")
        (:includes   . "<iostream> <algorithm> <vector> <string> <list>")))
;; is 'julia' block refers to 'jupyter-julia' block
;; (org-babel-jupyter-override-src-block "julia")

(defalias 'org-babel-execute:julia 'org-babel-execute:julia-vterm)

(setq org-highlight-latex-and-related '(native)
      org-pretty-entities-include-sub-superscripts nil
      org-format-latex-options '(:foreground default :background default :scale 1.7 :html-foreground "Black" :html-background "Transparent" :html-scale 1.0 :matchers
                                             ("begin" "$1" "$" "$$" "\\(" "\\[")))
(add-hook 'org-mode-hook 'org-toggle-pretty-entities)
(setq org-latex-compiler "xelatex")
(setq org-latex-listings 'minted
      org-latex-packages-alist '(("" "minted")
                                 ("" "tikz" t))
      ;; stop org adding hypersetup{author..} to latex export
      org-latex-with-hyperref nil)

(setq org-latex-pdf-process
      '("%latex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"
        "bibtex %b"
        "%latex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"
        "%latex -8bit -shell-escape -interaction nonstopmode -output-directory %o %f"))

;; (add-to-list 'org-latex-packages-alist
;; '("AUTO" "polyglossia" t ("xelatex" "lualatex")))

;; deleted unwanted file extensions after latexMK
(setq org-latex-logfiles-extensions
      '("lof" "lot" "tex~" "aux" "idx" "log"
        "out" "toc" "nav" "snm" "vrb" "dvi"
        "fdb_latexmk" "blg" "brf" "fls" "entoc"
        "ps" "spl" "bbl" "xmpi" "run.xml" "bcf"
        "acn" "acr" "alg" "glg" "gls" "ist"))

;; (unless (boundp 'org-latex-classes)
;;   (setq org-latex-classes nil))
;; (add-to-list 'org-latex-classes
;;              '("article"
;;                "\\documentclass{article}"
;;                ("\\section{%s}" . "\\section*{%s}")))

;; (setq org-preview-latex-default-process 'dvipng)
;; (setq org-format-latex-options (plist-put org-format-latex-options :scale 1.6))

;; (setq org-preview-latex-process-alist
;;       '((dvipng :programs
;;                 ("latex" "dvipng")
;;                 :description "dvi > png" :message "you need to install the programs: latex and dvipng." :image-input-type "dvi" :image-output-type "png" :image-size-adjust
;;                 (1.0 . 1.0)
;;                 :latex-compiler
;;                 ("latex -interaction nonstopmode -output-directory %o %f")
;;                 :image-converter
;;                 ("dvipng -D %D -T tight -o %O %f"))
;;         (dvisvgm :programs
;;                  ("latex" "dvisvgm")
;;                  :description "dvi > svg" :message "you need to install the programs: latex and dvisvgm." :image-input-type "dvi" :image-output-type "svg" :image-size-adjust
;;                  (1.7 . 1.5)
;;                  :latex-compiler
;;                  ("latex -interaction nonstopmode -output-directory %o %f")
;;                  :image-converter
;;                  ("dvisvgm %f -n -b min -c %S -o %O"))
;;         (imagemagick :programs
;;                      ("latex" "convert")
;;                      :description "pdf > png" :message "you need to install the programs: latex and imagemagick." :image-input-type "pdf" :image-output-type "png" :image-size-adjust
;;                      (1.0 . 1.0)
;;                      :latex-compiler
;;                      ("pdflatex -interaction nonstopmode -output-directory %o %f")
;;                      :image-converter
;;                      ("convert -density %D -trim -antialias %f -quality 100 %O"))))

(use-package cdlatex
  :bind (:map org-mode-map
              ("C-c e" . cdlatex-environment))
  :hook ((org-mode . org-cdlatex-mode))
  :ensure t
  :config
  (add-hook 'LaTeX-mode-hook 'turn-on-cdlatex)   ; with AUCTeX LaTeX mode
  (add-hook 'latex-mode-hook 'turn-on-cdlatex)   ; with Emacs latex mode
  (setq cdlatex-auto-help-delay 1.5
        cdlatex-simplify-sub-super-scripts nil
        cdlatex-make-sub-superscript-roman-if-pressed-twice t
        cdlatex-use-dollar-to-ensure-math nil)

  (setq cdlatex-env-alist
        '(("tikzpicture"
           "\\begin{tikzpicture}
?
\\end{tikzpicture}" nil))))

(use-package tex
  :straight nil
  :ensure auctex
  :config
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

(use-package org-ref
  :bind (:map org-mode-map
              ("C-c ]" . org-ref-helm-insert-cite-link)))

(require 'reftex)

(setq reftex-default-bibliography "~/zotero.bib")

(setq org-ref-default-bibliography "~/zotero.bib")

(use-package ox-pandoc)

(require 'ox-extra)

(ox-extras-activate '(latex-headers-blocks
                      ignore-headlines))

(use-package company-math
  :after company
  :config
  (setq company-tooltip-align-annotations t)
  (add-to-list 'company-backends 'company-math-symbols-unicode)
  (add-to-list 'company-backends 'company-math-symbols-latex))

(use-package company-org-block
  :after company
  :config
  (add-to-list 'company-backends 'company-org-block)
  (setq company-org-block-edit-style 'auto))

(use-package unicode-math-input)

(use-package xah-math-input
  :config
  (global-xah-math-input-mode 1))

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(use-package org-roam
  :demand t
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "/home/nabeel/org/roam/"))
  :config
  (org-roam-db-autosync-mode 1))

(use-package org-contrib
  :after org)

(use-package org-auto-tangle
  :hook (org-mode . org-auto-tangle-mode))

(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :config
  (setq org-superstar-remove-leading-stars t))


;; Replace list hyphen with dot
;; (font-lock-add-keywords 'org-mode
;;                         '(("^ *\\([-]\\) "
;;                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

;; Increase the size of various headings
(set-face-attribute 'org-document-title nil :font "Fira Code" :weight 'bold :height 1.3)
(dolist (face '((org-level-1 . 1.4)
                (org-level-2 . 1.3)
                (org-level-3 . 1.25)
                (org-level-4 . 1.2)
                (org-level-5 . 1.1)
                (org-level-6 . 1.1)
                (org-level-7 . 1.1)
                (org-level-8 . 1.1)))
  (set-face-attribute (car face) nil :font "Fira Code" :weight 'medium :height (cdr face)))


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
;; (require 'org-indent)

;; ;; Ensure that anything that should be fixed-pitch in Org files appears that way
;; (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
;; (set-face-attribute 'org-table nil  :inherit 'fixed-pitch)
;;   (set-face-attribute 'org-formula nil  :inherit 'fixed-pitch)
;;   (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
;; (set-face-attribute 'org-indent nil :inherit '(org-hide fixed-pitch))
;; (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
;;   (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
;; (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
;; (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch)

;; ;; Get rid of the background on column views
;;   (set-face-attribute 'org-column nil :background nil)
;;   (set-face-attribute 'org-column-title nil :background nil)

;; TODO: Others to consider
;; '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
;; '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;; '(org-property-value ((t (:inherit fixed-pitch))) t)
;; '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
;; '(org-table ((t (:inherit fixed-pitch :foreground "#83a598"))))
;; '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
;; '(org-verbatim ((t (:inherit (shadow fixed-pitch))))))

(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoentities t
        org-appear-autolinks t
        org-appear-autosubmarkers t))

(use-package org-download
  :after org
  :bind (:map org-mode-map
              ("C-M-y" . org-download-clipboard))
  :config

  (setq org-download-display-inline-images nil
        ;; to not insert the #+DOWNLOADED ... stuff
        org-download-annotate-function #'(lambda (link) (format ""))
        org-download-screenshot-method "flameshot gui")
  ;; Drag-and-drop to `dired`
  (add-hook 'dired-mode-hook 'org-download-enable))

(use-package ox-gfm)

(use-package org-pandoc-import
  :straight (org-pandoc-import
             :host github
             :repo "tecosaur/org-pandoc-import"
             :files ("*.el" "filters" "preprocessors"))
  :after org
  :config
  (org-pandoc-import-transient-mode -1))

(use-package org-sticky-header
  :hook (org-mode . org-sticky-header-mode)
  :config
  (setq org-sticky-header-full-path 'reversed))

(use-package org-noter
  :after org
  :config
  (setq org-noter-always-create-frame nil
        org-noter-separate-notes-from-heading t
        org-noter-doc-property-in-notes t
        org-noter-auto-save-last-location1 t))

(use-package org-pdftools
  :hook (org-mode . org-pdftools-setup-link))

(use-package org-noter-pdftools
  :after org-noter
  :config
  ;; Add a function to ensure precise note is inserted
  (defun org-noter-pdftools-insert-precise-note (&optional toggle-no-questions)
    (interactive "P")
    (org-noter--with-valid-session
     (let ((org-noter-insert-note-no-questions (if toggle-no-questions
                                                   (not org-noter-insert-note-no-questions)
                                                 org-noter-insert-note-no-questions))
           (org-pdftools-use-isearch-link t)
           (org-pdftools-use-freestyle-annot t))
       (org-noter-insert-note (org-noter--get-precise-info)))))

  ;; fix https://github.com/weirdNox/org-noter/pull/93/commits/f8349ae7575e599f375de1be6be2d0d5de4e6cbf
  (defun org-noter-set-start-location (&optional arg)
    "When opening a session with this document, go to the current location.
With a prefix ARG, remove start location."
    (interactive "P")
    (org-noter--with-valid-session
     (let ((inhibit-read-only t)
           (ast (org-noter--parse-root))
           (location (org-noter--doc-approx-location (when (called-interactively-p 'any) 'interactive))))
       (with-current-buffer (org-noter--session-notes-buffer session)
         (org-with-wide-buffer
          (goto-char (org-element-property :begin ast))
          (if arg
              (org-entry-delete nil org-noter-property-note-location)
            (org-entry-put nil org-noter-property-note-location
                           (org-noter--pretty-print-location location))))))))
  (with-eval-after-load 'pdf-annot
    (add-hook 'pdf-annot-activate-handler-functions #'org-noter-pdftools-jump-to-note)))

(use-package org-web-tools)

(use-package org-tree-slide
  :after org
  :bind (:map org-mode-map
              ("C-u <f5>" . org-tree-slide-skip-done-toggle)
              ("<f5>" . org-tree-slide-mode)
              :map org-tree-slide-mode-map
              ("C-x s h" . org-tree-slide-display-header-toggle)
              )
  :config
  (setq org-tree-slide-skip-done t)
  (org-tree-slide-simple-profile))
