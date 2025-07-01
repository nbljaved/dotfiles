(in-package :stumpwm)

(nbl/keyboard)
;; (run-shell-command "feh --bg-scale ~/Pictures/wallpaper/dark_mountain.jpg")
;; wallpaper
(xrandr-auto)
(run-shell-command "nm-applet") ; wifi
;;(run-shell-command "pasystray") ; volume
;;(run-shell-command "cbatticon") ; battery
(run-shell-command "dunst &") ; notification server
;; composter
(picom-start)
(wallpaper)
;; In order to start the agent automatically and make sure that only one ssh-agent process runs at a time
(nbl/start-ssh-agent)
;;
(udiskie-start)

(ignore-errors (ql:quickload :clx-truetype))
(ignore-errors
 (ql:quickload "ttf-fonts")
 ;; FONTS (FORGET ABOUT THIS !!!!!!!!!!!!!)
 (when (string-equal "pc" (string-trim '(#\Newline) (run-shell-command "hostname" t)))
   ;; Add https://github.com/goose121/clx-truetype to ~/quicklisp/local-projects/

   (setf xft:*font-dirs* '("/run/current-system/profile/share/fonts/"))
   (setf clx-truetype::+font-cache-filename+ (concat (getenv "HOME") "/.fonts/font-cache.sexp"))

   (xft:cache-fonts)
   (clx-truetype:cache-fonts)
   (set-font (make-instance 'xft:font :family "DejaVu Sans Mono" :subfamily "Book" :size 12))))

(defparameter *battery-low-timer*
  (run-with-timer 1                     ; delay of x no. of seconds
                  60                    ; repeat again in x no. of seconds
                  (lambda ()
                    (when (battery-low?)
                      (run-shell-command
                       "dunstify BATTERY LOW -u critical"))))
  "Use (cancel-timer *battery-low-timer*) to remove it.")

(defun redirect-stream (stream file)
  "Elect to redirect stream to the specified file. For instance,
if you want *debug-stream* to go to ~/.stumpwm.d/debug-stream.txt you would
do:

@example
(redirect-stream *debug-stream* (data-dir-file \"debug-stream\" \"txt\"))
@end example
"
  (let ((new-stream (open file :direction :output :if-exists :append :if-does-not-exist :create)))
    (setf stream new-stream)))

(redirect-stream *error-output* (data-dir-file "error-output" "txt"))
;; (redirect-stream *standard-output* (data-dir-file "standard-output" "txt"))
;; (redirect-stream *trace-output* (data-dir-file "trace-output" "txt"))
(redirect-stream *debug-stream* (data-dir-file "debug-stream" "txt"))
