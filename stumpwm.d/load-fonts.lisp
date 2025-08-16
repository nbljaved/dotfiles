(in-package :stumpwm)

(ignore-errors (ql:quickload :clx-truetype))
(ignore-errors
 (ql:quickload "ttf-fonts")
 ;; FONTS (FORGET ABOUT THIS !!!!!!!!!!!!!)

 ;; Add https://github.com/goose121/clx-truetype to ~/quicklisp/local-projects/

 (setf xft:*font-dirs* '("/run/current-system/profile/share/fonts/"))
 (setf clx-truetype::+font-cache-filename+ (concat (getenv "HOME") "/.fonts/font-cache.sexp"))

 (xft:cache-fonts)
 (clx-truetype:cache-fonts)
 (set-font (make-instance 'xft:font :family "DejaVu Sans Mono" :subfamily "Book" :size 17)))
