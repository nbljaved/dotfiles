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
(bluetooth-start)
(when pc?
  ;; Monitor going into sleep:
  ;; see current settings using `xset q`
  (screen-blank-time)

  ;; HiDPI
  ;; https://wiki.archlinux.org/title/HiDPI
  ;;
  ;; (THIS ->) https://wiki.archlinux.org/title/Xsettingsd

  ;;
  ;; 96 is default (0% scaling)
  ;; See https://dpi.lv/#3840%C3%972160 (for 3840x2160 res, and 32 inc
  ;; diagonal), dpi comes out to 138 pixels per inch, thereofore I am setting
  ;; the dpi to 144 (26 * 6)
  (xsettingsd-start))

(when pc?
  ;; to avoid reader error of 'package doesn't exist'
  (load "/home/nabeel/.stumpwm.d/load-fonts.lisp"))

(defparameter *battery-low-timer*
  (run-with-timer 1                     ; delay of x no. of seconds
                  60                    ; repeat again in x no. of seconds
                  (lambda ()
                    (when (battery-low?)
                      (run-shell-command
                       "dunstify BATTERY LOW -u critical"))))
  "Use (cancel-timer *battery-low-timer*) to remove it.")

