;; Start slynk server for use with sly
(load "~/quicklisp/setup.lisp")
;; load quicklisp
(asdf:load-system "slynk")
(slynk:create-server :port 4005 :dont-close t)

(asdf:load-system :stumpwm)
(in-package :stumpwm)

(defvar *config-dir* "~/.stumpwm.d/")

;; Default programs
(setf *suppress-abort-messages* nil)
(setf *top-level-error-action* :message)

;; Set stumpwm values
(setf *startup-message*                 "Take Responsibility."
      *mouse-focus-policy*             :click
      *shell-program* (stumpwm:getenv "SHELL")
      *maxsize-border-width*           5
      *normal-border-width*            5
      *transient-border-width*         2
      *run-or-raise-all-groups*        nil
      *run-or-raise-all-screens*       nil
      stumpwm::*float-window-border* 0
      stumpwm::*float-window-title-height* 0
      *window-border-style*            :thin
      *window-format*                 "%m%n%s%t")
(stumpwm:set-border-color "#1e90ff") ;;(dodger blue) for input bar and message bar
(stumpwm:set-focus-color "#836fff")  ;;(slate blue)
;;(setf *window-info-format*)
(setf *timeout-wait*                   6 )
(setf *input-window-gravity*           :center )
(setf *message-window-gravity*         :center)
;; (setf *grab-pointer-foreground* (xlib:make-color :red 0.1 :green 0.25 :blue 0.5))
;; (setf *grab-pointer-background* (lookup-color (current-screen) "DeepSkyBlue"))
(set-normal-gravity :center)
(set-maxsize-gravity :center)
(set-transient-gravity :center)
(clear-window-placement-rules)

;; (define-frame-preference "Default"
;; (0 nil t :class "Emacs")
;; (3 nil t :class "kitty")
;; (2 nil t :class "firefox"))

;;(setf *grab-pointer-character*         71 )
;;(setf *grab-pointer-character-mask*    71 )

;; Recount windows number on kill
;; (stumpwm:add-hook stumpwm:*destroy-window-hook*
;; #'(lambda (win) (stumpwm:repack-window-numbers)))
;;(remove-all-hooks *destroy-window-hook*)

;; Load other configuration files
(load "/home/nabeel/.stumpwm.d/modules.lisp")
(load "/home/nabeel/.stumpwm.d/defcommands.lisp")
(load "/home/nabeel/.stumpwm.d/keybinding.lisp")

;;
;; (when *initializing*
;;   (progn
;;     (load "/home/nabeel/.stumpwm.d/startup.lisp")
;;     ;; (launch-polybar)
;;     ))

(load "/home/nabeel/.stumpwm.d/startup.lisp")
(when *initializing*
  (progn
    (load "/home/nabeel/.stumpwm.d/startup.lisp")
    ;; (launch-polybar)
    ))
;; (load "/home/nabeel/.stumpwm.d/startup.lisp")

;; Load mode-line configuration 
(load "/home/nabeel/.stumpwm.d/modeline.lisp")



