(in-package :stumpwm)

(nbl/keyboard)
(run-shell-command "feh --bg-scale ~/Pictures/wallpaper/dark_mountain.jpg") ;; wallpaper
(xrandr-same)
(run-shell-command "nm-applet") ;; wifi
;;(run-shell-command "pasystray") ;; volume
;;(run-shell-command "cbatticon") ;; battery
(run-shell-command "dunst &") ;; notification server
;; composter
;; (run-shell-command "picom -bc")
;; In order to start the agent automatically and make sure that only one ssh-agent process runs at a time
(run-shell-command
 "if ! pgrep -u \"$USER\" ssh-agent > /dev/null; then
    ssh-agent -t 1h > \"$XDG_RUNTIME_DIR/ssh-agent.env\"
fi
if [[ ! \"$SSH_AUTH_SOCK\" ]]; then
    source \"$XDG_RUNTIME_DIR/ssh-agent.env\" >/dev/null
fi
")

;; FONTS
(ql:quickload :clx-truetype)
(load-module "ttf-fonts")
(setf xft:*font-dirs* '("/usr/share/fonts/"))
;; (setf clx-truetype:+font-cache-filename+ (concat (getenv "HOME") "/.fonts/font-cache.sexp"))

(xft:cache-fonts)

(clx-truetype:cache-fonts)
(set-font (make-instance 'xft:font :family "DejaVu Sans Mono" :subfamily "Book" :size 12))
