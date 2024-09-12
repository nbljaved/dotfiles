(in-package :stumpwm)

;; stumpwm prefix key
(stumpwm:set-prefix-key (stumpwm:kbd "s-w"))

;; Keyboard
(define-key *top-map* (kbd "C-s-k") "nbl/keyboard")

;;; Root map
(define-key *root-map* (kbd "b") "windowlist")
(define-key *root-map* (kbd "w") "windowlist") ;;windows
(define-key *root-map* (kbd "s-n") "renumber")
(define-key *root-map* (kbd "s-w") "other")

;; frame manipulation
(define-key *top-map* (kbd "C-q") "send-raw-key") ;; send raw key
(define-key *top-map* (kbd "s-:") "eval")
(define-key *top-map* (kbd "s-F") "fullscreen")
(define-key *top-map* (kbd "s-q") "delete")
(define-key *top-map* (kbd "s-Q") "kill")
(define-key *top-map* (kbd "s-d") "rofi")
(define-key *top-map* (kbd "s-o") "fnext") ;; like other buffer
(define-key *top-map* (kbd "s-TAB") "pull-hidden-next")
(define-key *top-map* (kbd "s-S-RET") "expose")
;; (define-key *top-map* (kbd "s-n") "window-mini") ;; switch to the window
;; (define-key *top-map* (kbd "s-n") "global-windowlist") ;; switch to the window
(define-key *top-map* (kbd "s-p") "global-pull-windowlist") ;; pull the the windwo to where you are
(define-key *menu-map* (kbd "s-n" ) 'menu-down)
(define-key *menu-map* (kbd "C-j" ) 'menu-down)
(define-key *menu-map* (kbd "s-p" ) 'menu-up)
(define-key *menu-map* (kbd "C-k" ) 'menu-up)

(define-key *root-map* (kbd "`") "remove-split")
(define-key *root-map* (kbd "1") "only")
(define-key *root-map* (kbd "2") "vsplit")
(define-key *root-map* (kbd "3") "hsplit")
;; (define-key *root-map* (kbd "C-`") "pull 0")
;; (define-key *top-map* (kbd "s-~") "remove-split")
;; (define-key *top-map* (kbd "s-!") "only")
;; (define-key *top-map* (kbd "s-@") "vsplit")
;; (define-key *top-map* (kbd "s-#") "hsplit")

(define-key *top-map* (kbd "s-0") "fclear")
(define-key *top-map* (kbd "Print") "flameshot")
(define-key *top-map* (kbd "s-P") "flameshot")
(define-key *top-map* (kbd "s-Print") "flameshot-launcher")
(define-key *top-map* (kbd "s-SPC") "emacs-everywhere")
(define-key *top-map* (kbd "s-B") "blueman-manager")

(define-key *top-map* (kbd "s-`") "nbl/select-window-by-number 0")
(define-key *top-map* (kbd "s-1") "nbl/select-window-by-number 1")
(define-key *top-map* (kbd "s-2") "nbl/select-window-by-number 2")
(define-key *top-map* (kbd "s-3") "nbl/select-window-by-number 3")
(define-key *top-map* (kbd "s-4") "nbl/select-window-by-number 4")
(define-key *top-map* (kbd "s-5") "nbl/select-window-by-number 5")
(define-key *top-map* (kbd "s-6") "nbl/select-window-by-number 6")
(define-key *top-map* (kbd "s-7") "nbl/select-window-by-number 7")
;; (define-key *top-map* (kbd "s-8") "sound-settings")
(define-key *top-map* (kbd "s-8") "nbl/select-window-by-number 8")
(define-key *top-map* (kbd "s-9") "nbl/select-window-by-number 9")
;; (define-key *top-map* (kbd "s-`") "nbl/emacs")
;; (define-key *top-map* (kbd "s-2") "firefox")


;; GROUP MANIPULATION
(define-key *top-map* (kbd "s-g") '*groups-map*)
(define-key *groups-map* (kbd "s-g") "gother")
(define-key *groups-map* (kbd "g") "grouplist")
(define-key *groups-map* (kbd "f") "gnew")


;; polybar manipulation
;; (defvar *polybar-map* (make-sparse-keymap))
;; (define-key *top-map* (kbd "s-P") '*polybar-map*)
;; (define-key *polybar-map* (kbd "p") "launch-polybar")
;; (define-key *polybar-map* (kbd "k") "kill-polybar")
;; (define-key *polybar-map* (kbd "r") "refresh-polybar")

;; xrandr
(defvar *xrandr-map* (make-sparse-keymap))
(define-key *top-map* (kbd "s-x") '*xrandr-map*)
(define-key *xrandr-map* (kbd "s-l") "xrandr-laptop")
(define-key *xrandr-map* (kbd "s-m") "xrandr-monitor")
(define-key *xrandr-map* (kbd "s-v") "xrandr-vertical")
(define-key *xrandr-map* (kbd "s-h") "xrandr-horizontal")
(define-key *xrandr-map* (kbd "s-s") "xrandr-same")
(define-key *xrandr-map* (kbd "s-r") "xrandr-right-of-laptop")
(define-key *xrandr-map* (kbd "s-x") "refresh-heads")

;; Launch applications
;; Add "run-or-raises" programs to root-map
(define-key *top-map* (kbd "s-RET") "terminal")
(define-key *top-map* (kbd "s-f") "firefox")
(define-key *top-map* (kbd "s-b") "chromium")
(define-key *top-map* (kbd "s-n") "nyxt")
(define-key *top-map* (kbd "s-m") "mpv")
(define-key *top-map* (kbd "s-e") "nbl/emacs")
(define-key *top-map* (kbd "s-E") "nbl/emacs-frame")
(define-key *top-map* (kbd "s-l") "nbl/lispworks")
(define-key *top-map* (kbd "s-s") "nbl/slack")
(define-key *top-map* (kbd "s-z") "nbl/zoom")
(define-key *top-map* (kbd "s-S") "sound-settings")
(define-key *top-map* (kbd "s-T") "file-manager")
(define-key *top-map* (kbd "s-O") "pdf-viewer")
;; (define-key *top-map* (kbd "s-;") "terminal")

(define-key *top-map* (kbd "s-ESC") "lock-screen")

(define-key *top-map* (kbd "s-A") "battery")
(define-key *top-map* (kbd "s-a") "time")
(define-key *top-map* (kbd "s-M") "nbl/toggle-mode-line")
(define-key *top-map* (kbd "s-G") "nbl/toggle-gaps")
;;(define-key *top-map* (kbd "s-"))

;; simulation keys
;; (define-remapped-keys
;;     `((,(lambda (win)
;; 	  (or (string-equal "firefox" (window-class win))
;; 	      (string-equal "Firefox" (window-class win))
;; 	      (string-equal "Chromium" (window-class win))))
;; 	("C-n"   . "Down")
;; 	("C-p"   . "Up")
;; 	("C-f"   . "Right")
;; 	("C-b"   . "Left")
;; 	("C-s"   . "C-f")
;; 	("C-d"   . "Delete")
;; 	("C-v"   . "Next")
;; 	("M-v"   . "Prior")
;; 	("M-w"   . "C-c")
;; 	("C-w"   . "C-x")
;; 	("C-y"   . "C-v")
;; 	("M-<"   . "Home")
;; 	("C-a"   . "Home")
;; 	("M->"   . "End")
;; 	("C-e"   . "End")
;; 	("C-M-b" . "M-Left")
;; 	("C-M-f" . "M-Right")
;; 	("M-f"   . "C-Right")
;; 	("M-b"   . "C-Left")
;; 	("C-k"   . ("C-S-End" "C-x"))
;; 	("M-j" . "C-S-Tab")
;; 	("M-l" . "C-Tab"))))

(define-remapped-keys
    `(("(firefox|Firefox|Chromium|Google-chrome|Zotero|zotero|okular|Okular|slack|Slack)"
       ("C-n"   . "Down")
       ("C-p"   . "Up")
       ("C-f"   . "Right")
       ("C-b"   . "Left")
       ("C-s"   . "C-f")
       ("C-d"   . "Delete")
       ("C-v"   . "Next")
       ("M-v"   . "Prior")
       ("M-w"   . "C-c")
       ("C-w"   . "C-x")
       ("C-y"   . "C-v")
       ("C-/"   . "C-z")
       ("M-<"   . "Home")
       ("M-less"   . "Home")
       ("C-a"   . "Home")
       ("M->"   . "End")
       ("M-greater"   . "End")
       ("C-e"   . "End")
       ("C-M-b" . "M-Left")
       ("C-M-f" . "M-Right")
       ("M-f"   . "C-Right")
       ("M-b"   . "C-Left")
       ("M-d"   . ("C-S-Right" "C-x"))
       ("C-k"   . ("C-S-End" "C-x"))
       ("M-j" . "C-S-Tab")
       ("M-l" . "C-Tab"))))

;;; Desktop Environment
;; Brightness
(define-key *top-map* (kbd "XF86MonBrightnessUp") "backlight-up")
(define-key *top-map* (kbd "XF86MonBrightnessDown") "backlight-down")

;; Volume
(define-key *top-map* (kbd "XF86AudioMute") "volume-mute")
(define-key *top-map* (kbd "XF86AudioRaiseVolume") "volume-up")
(define-key *top-map* (kbd "XF86AudioLowerVolume") "volume-down")
(define-key *top-map* (kbd "XF86AudioMicMute") "mic-mute")

;; dunst
(define-key *top-map* (kbd "C-S-SPC") "clear-notifications")
;; winner-mode
(defvar *winner-map* (make-sparse-keymap))

(defvar *message-filters* '("Group dumped.")
  "Don't show these messages.")

(defun message (fmt &rest args)
  "Overwritten message function to allow filters"
  (let ((msg-string (apply 'format nil fmt args)))
    (unless (member msg-string *message-filters* :test #'string=)
      (echo-string (current-screen) msg-string))))

(define-key *top-map* (kbd "s-c") '*winner-map*) 
(define-key *winner-map* (kbd "Left") "winner-undo") 
(define-key *winner-map* (kbd "Right") "winner-redo") 
(setf winner-mode:*tmp-folder* "~/.stumpwm.d/winner-layouts/") 
;; (defun nbl/winner-save (command) 
;;   (when (member 'command winner-mode:*default-commands*) 
;;     (winner-mode:dump-group-to-file))) 
;; (add-hook *post-command-hook* #'nbl/winner-save)

(add-hook *post-command-hook* (lambda (command)
                                (when (member command winner-mode:*default-commands*)
                                  (winner-mode:dump-group-to-file))))
;(remove-all-hooks *post-command-hook*)




