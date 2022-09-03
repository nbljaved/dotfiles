(in-package :stumpwm)

;; toggle modeline (for live editing)
;https://github.com/stumpwm/stumpwm-contrib.git; (stumpwm:toggle-mode-line (stumpwm:current-screen) (stumpwm:current-head))
(setf *time-modeline-string* "%a %m-%d ^5*^B%l:%M^b^n")

(setf *mode-line-timeout* 5)
(setf stumpwm:*mode-line-position* :top)

(setf *mode-line-background-color* "#483d8b")

(setq *separator* " ^7*^B||^b")

(setf stumpwm:*screen-mode-line-format*
      (list
       "^B[^b"                      ; [
       "^1*%n^n"                    ; Current Group
       "^B]^b"                      ; ]
       ;;" ^2*/^n "                   ; ---
       "^7*^B%W^b^n"                ; Focused frame
       "^>"                         ; middle
       ;; "^3*^b%C "                    ; cpu
       ;; "^2*^b%M"                    ; Memory
       ;; "^6*[^n^B%I^b^6*]^n %l"      ; net
                                        ;*separator-right*            ; ---
                                        ;"^6*[^n^B%I^b^6*]^n %I"      ; wifi
       '(:eval (string-right-trim '(#\Newline) (run-shell-command
                                                "date +'^B%d-%m ^B%a ^6*%R^b'" t)))
       ;; " ^B◎ %d" ; date and time using
       ))

;; ;; display mode line
;; (dolist (head
;;          (list (first (screen-heads (current-screen)))))
;;   (enable-mode-line (current-screen) head
;;                     t *screen-mode-line-format*))

;; (stumptray:stumptray)
