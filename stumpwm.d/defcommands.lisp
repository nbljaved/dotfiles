(in-package :stumpwm)

;; Keyboard
(defcommand nbl/keyboard () ()
  "setxbmap setting"
  (run-shell-command "setxkbmap -option caps:menu -option shift:both_capslock_cancel"))


;; toggle modeline
(defcommand nbl/toggle-mode-line () ()
  "turn on/off the mode line for the current head only."
  (stumpwm:toggle-mode-line (stumpwm:current-screen)
			    (stumpwm:current-head)))

;; ;; swm-gaps toggle
(defcommand nbl/toggle-gaps () ()
  "turn on/off the gaps"
  (swm-gaps:toggle-gaps))


;; 🔋
(defcommand battery () ()
  (message (run-shell-command "acpi" t)))

;; xrandr
(defcommand xrandr-laptop () ()
  (run-shell-command "xrandr --output HDMI-2 --off --output eDP-1 --primary --auto"))
(defcommand xrandr-monitor () ()
  (run-shell-command "xrandr --output HDMI-2 --primary --mode 2560x1440 --output eDP-1 --off"))
(defcommand xrandr-vertical () ()
  (run-shell-command "xrandr --output HDMI-2 --primary --rotation left --auto --output eDP-1 --rotation normal --auto --left-of HDMI-2"))
(defcommand xrandr-horizontal () ()
  (run-shell-command "xrandr --output eDP-1 --primary --rotate normal --auto --output HDMI-2 --rotate normal"))
(defcommand xrandr-same () ()
  (run-shell-command "xrandr --output eDP-1 --primary --auto --output HDMI-2 --auto --same-as eDP-1")
  ;;  (run-shell-command "xrandr --output eDP-1 --mode 1920x1080 --output HDMI-2 --mode 1920x1080 --same-as eDP-1")
  )
(defcommand xrandr-right-of-laptop () ()
  (run-shell-command "xrandr --output eDP-1 --primary --output HDMI-2 --auto --right-of eDP-1"))


;;; Polybar
(defcommand launch-polybar () ()
  (run-shell-command "sh ~/.config/polybar/launch.sh"))
(defcommand kill-polybar () ()
  (run-shell-command "polybar-msg cmd quit"))
(defcommand refresh-polybar () ()
  (run-commands "kill-polybar" "launch-polybar" "nbl/toggle-mode-line" "nbl/toggle-mode-line"))

;;;; Run or raise most used programs
(defcommand firefox () ()
  "Run-or-Raise Firefox"
  ;; --sync makes the X calls synchronous
  (run-or-raise "firefox" '(:class "firefox")))

(defcommand chromium () ()
  "Run-or-Raise Chromium"
  (run-or-raise "chromium" '(:class "Chromium")))

(defcommand google-chrome () ()
  "Run-or-Raise Chrome"
  (run-or-raise "google-chrome-stable" '(:class "Google-chrome")))

(defcommand mpv () ()
  "Run-or-Raise mpv"
  (run-or-raise "mpv" '(:class "mpv")))

(defcommand nyxt () ()
  "Run-or-Raise Nyxt"
  (run-or-raise "nyxt" '(:class "Nyxt")))

(defcommand nbl/emacs () ()
  "Run-or-Raise Emacs"
  (run-or-raise "emacs --debug-init" '(:class "Emacs" :instance "emacs")))
(defcommand nbl/emacs-frame () ()
  "launch a new emacs frame provided the server is running"
  (run-shell-command "emacsclient -c"))

(defcommand nbl/lispworks () ()
  "lispworks"
  (run-or-raise "ros -L run lispworks" '(:class "Lw-console")))

(defcommand rofi () ()
  "rofi"
  (run-or-raise "rofi -show run" '(:class "rofi")))

;; Rofi (for window switching)
(defcommand window-mini () ()
  "show all windows using rofi"
  (run-or-raise "rofi -show window" '(:class "rofi")))


(defcommand terminal () ()
  "Run-or-Raise Terminal"
  (run-or-raise "kitty" '(:class "kitty")))

(defcommand file-manager () ()
  "Run-or-Raise File Manager"
  (run-or-raise "dolphin" '(:class "dolphin")))

(defcommand pdf-viewer () ()
  "Run-or-Raise pdf-viewer"
  (run-or-raise "okular" '(:class "okular")))

(defcommand sound-settings () ()
  "Open sound settings"
  (run-or-raise "pavucontrol" '(:class "Pavucontrol")))

(defcommand nbl/slack () ()
  "Run-or-raise slack"
  (run-or-raise "slack" '(:class "Slack")))

(defcommand nbl/zoom () ()
  "Run-or-raise zoom"
  (run-or-raise "zoom" '(:class "zoom")))

;; Brightness control
(defcommand backlight-up () ()
  "Up backlight by 20"
  (run-shell-command "brightnessctl s +50" )
  (run-shell-command "notify-send \"Brightness\" $(brightnessctl | awk -F\" \" '/Current/ {print $4}')"))

(defcommand backlight-down () ()
  "Up backlight by 20"
  (run-shell-command "brightnessctl s 50-")
  (stumpwm:run-shell-command " notify-send \"Brightness\" $(brightnessctl | awk -F\" \" '/Current/ {print $4}') "))

(defcommand mic-mute () ()
  "Mute / Unmute microphone"
  (run-shell-command "pactl set-source-mute @DEFAULT_SOURCE@ toggle"))

;; Volumes control
(defcommand volume-mute () ()
  "Mute / Unmute volume"
  (run-shell-command "pactl set-sink-mute @DEFAULT_SINK@ toggle")
  (run-shell-command  "notify-send \"Volume\" $(pamixer --get-volume-human) " t))

(defcommand volume-up () ()
  "Mute / Unmute volume"
  (run-shell-command "pactl -- set-sink-volume @DEFAULT_SINK@ +5%")
  (run-shell-command  "notify-send \"Volume\" $(pamixer --get-volume-human) " t))

(defcommand volume-down () ()
  "Mute / Unmute volume"
  (run-shell-command "pactl -- set-sink-volume @DEFAULT_SINK@ -5%" )
  (run-shell-command  "notify-send \"Volume\" $(pamixer --get-volume-human) " t))


(defcommand lock-screen () ()
  "Uses ~/bin/lockscreen.sh to lock the screen"
  (run-shell-command "i3lock -c 2e2e2e")) 

(defcommand flameshot () ()
  "Launch flameshot for screenshot"
  (run-shell-command "flameshot gui"))

(defcommand flameshot-launcher () ()
  (run-shell-command "flameshot launcher"))

;; Window selection
(defcommand nbl/select-window-by-number (n) ((:number "enter window number"))
  (let ((x (stumpwm:current-window)))
    (if (and x ;; if no window (i.e on running fclear)
	     (eq (stumpwm:window-number x) n))
	(stumpwm:other-window)
	(stumpwm:select-window-by-number n))))

;; emacs everywhere
(defcommand emacs-everywhere () ()
  (run-shell-command "emacsclient --eval \"(emacs-everywhere)\""))

(defcommand blueman-manager () ()
  (run-or-raise "blueman-manager" '(:instance "blueman-manager")))

;; Fixed window numbers for certain programs
;; https://github.com/stumpwm/stumpwm/wiki/Tips-And-Tricks
(defparameter *window-class-renumber*
  '(
    ("Emacs" . 0)
    ("firefox" . 2)
    ("kitty" . 3)
    ("Pavucontrol" . 8)
    )
  "Alist of window classes to be renumbered, and their target numbers.")

(defun renumber-window-by-class (win)
  "Renumber window if its class matches *window-class-renumber*."

  (let* ((class (window-class win))
         (target-number (cdr (assoc class *window-class-renumber*
                                    :test #'string=))))

    (when target-number
      (let ((other-win (find-if #'(lambda (win)
                                    (= (window-number win) target-number))
                                (group-windows (window-group win)))))
        (if other-win
            (when (string-not-equal class (window-class other-win))
              ;; other window, different class; switch numbers
              (setf (window-number other-win) (window-number win))
              (setf (window-number win) target-number))
            ;; if there's already a window of this class, do nothing.
            ;; just keep the new number for this window.

            ;; else: no other window; target number is free.
            (setf (window-number win) target-number))

        ;; finally
        (update-all-mode-lines)))))

(add-hook *new-window-hook* 'renumber-window-by-class)
