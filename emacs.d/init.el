(setq debug-on-error t)
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

(defvar guix? (executable-find "guix")
  "Boolean to check if guix exists on current system")

(when guix?
  (defvar guix-profile-path (or (getenv "GUIX_PROFILE")
			        (concat (getenv "HOME")
				        "/.guix-profile"))
    "Value of environment variable $GUIX_PROFILE.")

  (defvar guix-checkout-path (or (getenv "GUIX_CHECKOUT")
                                 (concat (getenv "HOME")
                                         "/src/guix"))
    "Value of environment variable $GUIX_CHECKOUT, i.e. the location
of checked out guix repo https://git.savannah.gnu.org/git/guix.git")

  (let ((default-directory (concat guix-profile-path
                                   "/share/emacs/site-lisp/")))
    (normal-top-level-add-subdirs-to-load-path)))

(defvar elpaca-installer-version 0.6)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (call-process "git" nil buffer t "clone"
                                       (plist-get order :repo) repo)))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install a package via the elpaca macro
;; See the "recipes" section of the manual for more details.

;; (elpaca example-package)

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))

;; Block until current queue processed.
(elpaca-wait)

;;When installing a package which modifies a form used at the top-level
;;(e.g. a package which adds a use-package key word),
;;use `elpaca-wait' to block until that package has been installed/configured.
;;For example:
;;(use-package general :demand t)
;;(elpaca-wait)

;; Expands to: (elpaca evil (use-package evil :demand t))
;; (use-package evil :demand t)

;;Turns off elpaca-use-package-mode current declaration
;;Note this will cause the declaration to be interpreted immediately (not deferred).
;;Useful for configuring built-in emacs features.
(use-package emacs :elpaca nil :config (setq ring-bell-function #'ignore))

;; Don't install anything. Defer execution of BODY
(elpaca nil (message "deferred"))

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

(column-number-mode 1)

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
  :init (doom-modeline-mode 1)
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
  (modus-themes-load-theme 'modus-vivendi))

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
;;(add-hook 'prog-mode-hook 'linum-mode)

;;(electric-pair-mode -1)

;; highlight matching parenthesis
(show-paren-mode 1)

;; selected text is overwritten by the text we type
(delete-selection-mode 1)

;; Cycle spaces
(global-set-key (kbd "M-SPC") 'cycle-spacing)

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
         ("M-0". eyebrowse-switch-to-window-config)
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

(setq-default cursor-in-non-selected-windows '(hbar . 5))

(use-package multiple-cursors
  :bind (("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)
         ("C-S-<mouse-1>" . mc/add-cursor-on-click)))

(use-package treemacs)

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
         ("C-d" . company-show-doc-buffer)
         ("M-." . company-show-location)
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

(use-package counsel)

(use-package swiper
  :init
  (defun nbl/swiper ()
    ;; if some text is selected, use
    ;; that as the search string.
    (interactive)
    (if (use-region-p)
        (swiper-thing-at-point)
      (swiper)))
  :bind (("C-s" . nbl/swiper)
         ("C-M-s" . swiper-isearch)))

;; The `vertico' package applies a vertical layout to the minibuffer.
;; It also pops up the minibuffer eagerly so we can see the available
;; options without further interactions.  This package is very fast
;; and "just works", though it also is highly customisable in case we
;; need to modify its behaviour.
;;
(use-package vertico
  :ensure t
  :config
  (setq vertico-cycle nil)
  (setq vertico-resize nil)
  (vertico-mode 1))

;; The `marginalia' package provides helpful annotations next to
;; completion candidates in the minibuffer.  The information on
;; display depends on the type of content.  If it is about files, it
;; shows file permissions and the last modified date.  If it is a
;; buffer, it shows the buffer's size, major mode, and the like.
;;
(use-package marginalia
  :ensure t
  :config
  (marginalia-mode 1))

;; The `orderless' package lets the minibuffer use an out-of-order
;; pattern matching algorithm.  It matches space-separated words or
;; regular expressions in any order.  In its simplest form, something
;; like "ins pac" matches `package-menu-mark-install' as well as
;; `package-install'.  This is a powerful tool because we no longer
;; need to remember exactly how something is named.
;;
;; Note that Emacs has lots of "completion styles" (pattern matching
;; algorithms), but let us keep things simple.
;;
(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)))

;; The `consult' package provides lots of commands that are enhanced
;; variants of basic, built-in functionality.  One of the headline
;; features of `consult' is its preview facility, where it shows in
;; another Emacs window the context of what is currently matched in
;; the minibuffer.  Here I define key bindings for some commands you
;; may find useful.  The mnemonic for their prefix is "alternative
;; search" (as opposed to the basic C-s or C-r keys).
;;
;; Further reading: https://protesilaos.com/emacs/dotemacs#h:22e97b4c-d88d-4deb-9ab3-f80631f9ff1d
(use-package consult
  :ensure t
  :bind (;; A recursive grep
         ("M-s M-g" . consult-grep)
         ;; Search for files names recursively
         ("M-s M-f" . consult-find)
         ;; Search through the outline (headings) of the file
         ("M-s M-o" . consult-outline)
         ;; Search the current buffer
         ;; ("C-s" . consult-line)
         ;; Switch to another buffer, or bookmarked file, or recently
         ;; opened file.
         ("C-x C-b" . consult-recent-file)
         ("C-x b" . consult-buffer))
  :config
  (setq consult-line-start-from-top nil))

(use-package consult-dir
  :ensure t
  :bind (("C-x C-d" . consult-dir)
         :map vertico-map
         ("C-x C-d" . consult-dir)
         ("C-x C-j" . consult-dir-jump-file))
  :config
  (global-set-key (kbd "C-x C-d") 'consult-dir))

;; The `embark' package lets you target the thing or context at point
;; and select an action to perform on it.  Use the `embark-act'
;; command while over something to find relevant commands.
;;
;; When inside the minibuffer, `embark' can collect/export the
;; contents to a fully fledged Emacs buffer.  The `embark-collect'
;; command retains the original behaviour of the minibuffer, meaning
;; that if you navigate over the candidate at hit RET, it will do what
;; the minibuffer would have done.  In contrast, the `embark-export'
;; command reads the metadata to figure out what category this is and
;; places them in a buffer whose major mode is specialised for that
;; type of content.  For example, when we are completing against
;; files, the export will take us to a `dired-mode' buffer; when we
;; preview the results of a grep, the export will put us in a
;; `grep-mode' buffer.
;;
;; Further reading: https://protesilaos.com/emacs/dotemacs#h:61863da4-8739-42ae-a30f-6e9d686e1995
(use-package embark
  :ensure t
  :bind (("C-." . embark-act)
         :map minibuffer-local-map
         ("C-c C-c" . embark-collect)
         ("C-c C-e" . embark-export)))

;; The `embark-consult' package is glue code to tie together `embark'
;; and `consult'.
(use-package embark-consult
  :ensure t)

;; The `wgrep' packages lets us edit the results of a grep search
;; while inside a `grep-mode' buffer.  All we need is to toggle the
;; editable mode, make the changes, and then type C-c C-c to confirm
;; or C-c C-k to abort.
;;
;; Further reading: https://protesilaos.com/emacs/dotemacs#h:9a3581df-ab18-4266-815e-2edd7f7e4852
(use-package wgrep
  :ensure t
  :bind ( :map grep-mode-map
          ("e" . wgrep-change-to-wgrep-mode)
          ("C-x C-q" . wgrep-change-to-wgrep-mode)
          ("C-c C-c" . wgrep-finish-edit)))

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
  (define-key yas-minor-mode-map (kbd "SPC") yas-maybe-expand)
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

(use-package hungry-delete
  :config
  (setf hungry-delete-join-reluctantly t)
  (global-hungry-delete-mode))

;; (global-set-key (kbd "C-`") 'delete-window)
;; (global-set-key (kbd "C-1") 'delete-other-windows)
;; (global-set-key (kbd "C-2") 'split-window-below)
;; (global-set-key (kbd "C-3") 'split-window-right)

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

(use-package avy
  :demand t
  :config
  (global-set-key (kbd "<menu>") #'avy-goto-char-timer))

(use-package ace-isearch
  :config
  (global-ace-isearch-mode 1))

(setq recentf-max-saved-items 5000
      recentf-max-menu-items 100)
(setq recentf-save-file "~/.emacs.d/recentf")
;; save recentf-list every 1 minutes
(run-at-time nil (* 1 60) 'recentf-save-list)
(recentf-mode 1)

(use-package recentf-ext)

;; The built-in `savehist-mode' saves minibuffer histories.  Vertico
;; can then use that information to put recently selected options at
;; the top.
;;
;; Further reading: https://protesilaos.com/emacs/dotemacs#h:25765797-27a5-431e-8aa4-cc890a6a913a
(savehist-mode 1)

(use-package hydra
  :ensure t)

(require 'term)

(define-key term-mode-map (kbd "C-o") 'other-window)
(define-key term-raw-map (kbd "C-o") 'other-window)

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

(use-package dired-open
  :bind (:map dired-mode-map
              ("J" . dired-open-xdg)))

(use-package dired-open-with
  :bind (:map dired-mode-map
              ("C-u J" . dired-open-with)))

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

(use-package dired-preview)

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
  :bind (:map pdf-view-mode-map
              ("C-s" . isearch-forward))
  :config
  )

;;(pdf-tools-install t)

(use-package pdf-view-restore
  :after pdf-tools
  :config
  (add-hook 'pdf-view-mode-hook 'pdf-view-restore-mode))

(require 'info)
(when guix?
  (add-to-list 'Info-additional-directory-list
	       (concat guix-profile-path
		       "/share/info/")))

(use-package which-key
  :config
  (which-key-mode 1))

(use-package disk-usage)

(use-package trashed)
(setq delete-by-moving-to-trash t)

(use-package docker
  :ensure t
  :bind (("C-c d" . docker)))

(use-package docker-compose-mode)

(use-package dockerfile-mode
  :ensure t
  :config
  (add-to-list 'auto-mode-alist '("Dockerfile\\'" . dockerfile-mode)))

(when guix?
  (require 'guix-autoloads))

(use-package gptel
  :config
  ;; Register a backend
  ;; Together.ai offers an OpenAI compatible API
  (setq-default gptel-backend (gptel-make-openai "TogetherAI" ;Any name you want
                                :host "api.together.xyz"
                                :key (gptel-api-key-from-auth-source "api.together.xyz")
                                :stream t
                                :models '(;; has many more, check together.ai
                                          "mistralai/Mixtral-8x7B-Instruct-v0.1"
                                          "codellama/CodeLlama-13b-Instruct-hf"
                                          "codellama/CodeLlama-34b-Instruct-hf")))
  (global-set-key (kbd "C-x C-l") 'gptel-send)
  (global-set-key (kbd "C-x l") 'gptel-abort))

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

;;;; colorize output in compile buffer
(require 'ansi-color)
(defun colorize-compilation-buffer ()
  (ansi-color-apply-on-region compilation-filter-start (point)))
(add-hook 'compilation-filter-hook 'colorize-compilation-buffer)

;;
;;(define-key compilation-mode-map (kbd "C-o") 'other-window)

(require 'eww)
(setq browse-url-browser-function 'browse-url-default-browser
      ;; browse-url-browser-function 'eww-browse-url
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

(use-package rg
  :config
  (rg-enable-default-bindings))

(use-package topsy
  :hook (prog-mode . topsy-mode))

(use-package emacs-everywhere)

(use-package json-mode)

;;(use-package json-navigator)

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

(use-package indent-tools
  :config
  (global-set-key (kbd "C-c >") 'indent-tools-hydra/body))

(defun nbl/org-toggle-inline-images () (interactive)
       (org-toggle-inline-images 1))

(use-package ssh-config-mode)

(setq auth-sources '("~/.authinfo"))

(use-package ledger-mode)

(use-package devdocs
  :bind (("C-h D" . devdocs-lookup))
  :config
  (add-hook 'java-mode-hook
            (lambda () (setq-local devdocs-current-docs '("openjdk~18")))))

(use-package crdt
  :bind (:map crdt-mode-map
              ("C-c p" . crdt-list-users)
              ("C-c b" . crdt-list-buffers)
              ("C-c s" . crdt-list-sessions)
              ("C-x C-b" . crdt-switch-to-buffer))
  :config
  (setq crdt-visualize-author-mode t
        crdt-use-tuntox t
        crdt-tuntox-executable "~/.emacs.d/manual/tuntox-x64"))

(use-package pfuture)

(use-package nov
  ;;:hook (nov-mode . olivetti-mode)
  :config
  (add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))
  (setq nov-unzip-program "/usr/bin/unzip")
  )

(use-package nyan-mode
  :config
  (setq nyan-animate-nyancat t)
  (setq nyan-wavy-trail nil)
  ;; (setq nyan-)
  (nyan-mode 1))

(use-package mlscroll
  :config
  ;; truncate which-func, for default mode-line-format's
  (setq mlscroll-shortfun-min-width nil)
  (setq mlscroll-right-align nil
        mlscroll-alter-percent-position 'replace)
  (mlscroll-mode 1))

(use-package beacon
  :config
  (setq beacon-blink-when-focused t
        beacon-blink-when-buffer-changes t)
  (beacon-mode 1))

(use-package info-colors
  :commands (info-colors-fontify-node))

(add-hook 'Info-selection-hook 'info-colors-fontify-node)

(use-package camera
  :elpaca (camera :type git
                  :repo "https://codeberg.org/akib/emacs-camera.git"))

(use-package lsp-mode
  :init
  ;; set prefix for lsp-command-keymap (few alternatives - "C-l", "C-c l")
  (setq lsp-keymap-prefix "C-c l")
  :hook (;; replace XXX-mode with concrete major-mode(e. g. python-mode)
         (c++-mode . lsp-deferred)
         ;; if you want which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred)
  :config)

(use-package lsp-ui :commands lsp-ui-mode)
;; if you are helm user
(use-package helm-lsp :commands helm-lsp-workspace-symbol
  :config
  (define-key lsp-mode-map [remap xref-find-apropos] #'helm-lsp-workspace-symbol))

(use-package lsp-treemacs :commands lsp-treemacs-errors-list)

;; optionally if you want to use debugger
(use-package dap-mode
  :config
  (require 'dap-firefox)
  ;; Have to do 'M-x dap-firefox-setup',
  ;; then dap-firefox-debug-program will have valid path on your system.
  )

;; (use-package dap-LANGUAGE) to load the dap adapter for your language


;; company-lsp
;; (use-package company-lsp
;;   ;;:commands company-lsp
;;   :config
;;   (push 'company-lsp company-backends)
;;   (setq company-lsp-async t
;; 	company-lsp-enable-snippet t
;; 	company-lsp-enable-recompletion t
;; 	company-lsp-cache-candidates nil))

(use-package eglot
  :elpaca nil
  :bind (:map eglot-mode-map
              ("C-c h" . eldoc)
              ("C-c r" . eglot-rename)
              ("M-." . xref-find-definitions)
              ("M-?" . xref-find-references))
  :config
  (setq eglot-connect-timeout 30
        eglot-extend-to-xref t))

(use-package ninja-mode)

;; (setq inferior-lisp-program "ros -Q run -- --dynamic-space-size 32000 --control-stack-size 4096")
(setq inferior-lisp-program "sbcl --dynamic-space-size 32000 --control-stack-size 4096")
(setq max-lisp-eval-depth 8000)

;; .mlisp
(add-to-list 'auto-mode-alist '("\\.mlisp\\'" . lisp-mode))

(make-directory "~/.roswell" :parents)

(use-package sly
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
        '((sbcl ;; ("ros" "-Q" "run" "--" "--dynamic-space-size" "32000" "--control-stack-size" "4096")
           ("sbcl" "--dynamic-space-size" "32000" "--control-stack-size" "4096"))
          (lispworks ("ros" "-Q" "-L" "lispworks" "run"))))

  ;;(require 'sly-cl-indent (concat (getenv "HOME") "/.emacs.d/straight/repos/sly/lib/sly-cl-indent.el"))
  ;; To have Sly perform the indentation in the preferred style for Common Lisp code
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

(setq browse-url-firefox-program "firefox")

;; Or Google Chrome:

;; (setq browse-url-browser-function 'browse-url-generic)
;; (setq browse-url-generic-program "google-chrome")

(use-package eros)

(use-package geiser
  :config
  (setq geiser-active-implementations '(guile))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((scheme . t))))

(use-package geiser-guile
  :config
  (setq geiser-guile-binary (concat guix-profile-path "/bin/guile"))
  (when guix?
    (with-eval-after-load 'geiser-guile
      (add-to-list 'geiser-guile-load-path guix-checkout-path))))

(defun geiser-racket--language () '())

(use-package racket-mode
  :mode ("\\.rkt\\'" . racket-mode)
  :bind (:map racket-mode-map
              ("C-c C-p" . racket-cycle-paren-shapes))
  :config
  ;; the below RACKET-UNICODE-INPUT-METHOD-ENABLE caused problems with LISPY
  ;; (add-hook 'racket-mode-hook      #'racket-unicode-input-method-enable)
  ;; (add-hook 'racket-repl-mode-hook #'racket-unicode-input-method-enable)

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((racket . t))))

(use-package sicp)

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

(use-package prism
  :hook ((lispy-mode . prism-mode)))

(use-package go-mode
  :config
  (add-hook 'before-save-hook 'gofmt-before-save))

(use-package ob-go
  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((go . t))))

(use-package web-mode
  :config
  (setq web-mode-content-types-alist
        '(("jsx" . "\\.js[x]?\\'")
          ("tsx" . "\\.ts[x]?\\'"))))

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

(use-package js2-mode
  ;; :hook ((js-mode . lsp-deferred))
  :config
  ;; To install it as your major mode for JavaScript editing:
  (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))

  (add-to-list 'auto-mode-alist '("\\.ts[x]?\\'" . js2-mode))
  (add-to-list 'auto-mode-alist '("\\.jsx\\'" . js-mode))
  ;; Use Emacs 27 and want to write JSX?
  (add-hook 'js-mode-hook 'js2-minor-mode))


  ;; You may also want to hook it in for shell scripts running via node.js:
  (add-to-list 'interpreter-mode-alist '("node" . js2-mode))

(use-package nodejs-repl
  :config
  ;; (defun nvm-which ()
  ;;   (let* ((shell (concat (getenv "SHELL") " -l -c 'nvm which'"))
  ;;          (output (shell-command-to-string shell)))
  ;;     (cadr (split-string output "[\n]+" t))))
  (setq nodejs-repl-command "node"))

(use-package nvm)

(use-package python-mode
  :mode ("[./]flake8\\'" . conf-mode)
  :mode ("/Pipfile\\'" . conf-mode)
  :config
  (add-to-list 'exec-path "/home/nabeel/.local/bin")
  )


;; (add-hook 'python-mode-hook 'eglot-ensure)
;; (add-to-list 'eglot-server-programs '(foo-mode . ("foo-language-server" "--args")))
;; (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))

(use-package lpy
  :after counsel
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

(use-package pyenv-mode
  :config
  (require 'pyenv-mode))

(defun projectile-pyenv-mode-set ()
  "Set pyenv version matching project name."
  (let ((project (projectile-project-name)))
    (if (member project (pyenv-mode-versions))
        (pyenv-mode-set project)
      (pyenv-mode-unset))))

(add-hook 'projectile-after-switch-project-hook 'projectile-pyenv-mode-set)

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

(use-package flymake-shellcheck
  :commands flymake-shellcheck-load
  :init
  (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

(use-package org
  :elpaca nil
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
        ;; org links
        help-at-pt-display-when-idle t
        )
  (help-at-pt-set-timer)
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
   (sqlite . t)
   (python . t)
   (java . t)
   (C . t)
   (lisp . t)
   (emacs-lisp . t)
   (octave . t)
   (maxima . t)
   (shell . t)
   ;;(julia . t)
   ;; (julia-vterm . t)
   ;;(ein . t)
   ;;(jupyter . t)
   ))

(setq org-babel-lisp-eval-fn 'sly-eval)
(setq org-babel-python-command "python3")

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

(use-package texfrag
  :bind ((:map texfrag-mode-map
               ("C-c C-p" . org-previous-visible-heading)))
  :config
  (setq-default texfrag-scale 0.7
                texfrag-preview-buffer-at-start nil))

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

(use-package auctex
  :elpaca  (auctex
            :pre-build (("./autogen.sh")
                        ("./configure"
                         "--without-texmf-dir"
                         "--with-packagelispdir=./"
                         "--with-packagedatadir=./")
                        ("make"))
            :build (:not elpaca--compile-info) ;; Make will take care of this step
            :files ("*.el" "doc/*.info*" "etc" "images" "latex" "style")
            :version (lambda (_) (require 'tex-site) AUCTeX-version))
  ;; :mode (("\\.tex\\'" . LaTeX-mode))
  :config
  (add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer))

(when guix?
  (let* ((texlive-path (string-trim
                        (shell-command-to-string
                         "guix build --dry-run texlive")))
         (texlive-bin (concat texlive-path "/bin")))
    (cl-pushnew texlive-bin exec-path)
    texlive-bin))

(use-package org-ref
  :bind (:map org-mode-map
              ("C-c ]" . org-ref-helm-insert-cite-link)))

(require 'reftex)

(setq reftex-default-bibliography "~/zotero.bib")

(setq org-ref-default-bibliography "~/zotero.bib")

(use-package ox-pandoc)

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

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

(make-directory "~/org/roam" :parents)

(use-package org-roam
  :demand t
  :init
  (setq org-roam-v2-ack t)
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
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
        org-appear-autolinks nil
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

(use-package org-transclusion
  :bind (("<f12>" . org-transclusion-add)
         (:map org-transclusion-map
               ("<f12>". org-transclusion-remove)))
  :config
  (set-face-attribute
   'org-transclusion-fringe nil
   :foreground "white smoke"
   :background "white smoke"))

(use-package org-pandoc-import
  :elpaca (org-pandoc-import
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

(use-package anki-editor)
