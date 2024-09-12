(in-package :stumpwm)
(ql:quickload :alexandria)
(ql:quickload :clx)
(ql:quickload :cl-ppcre)

;; (setf *contrib-dir* #P"/home/nabeel/.stumpwm.d/modules/")
(setf *module-dir* #P"/home/nabeel/.stumpwm.d/modules/")
(init-load-path *module-dir*)
;; modeline
(load-module "cpu")
(load-module "mem")
(ql:quickload "xembed")
(load-module "stumptray")
(load-module "net")
(load-module "wifi")

(load-module "winner-mode")

;; stuff that should be in the module but isn't
(load-module "undocumented")

;; summon mouse to your current window
;; (load-module "beckon")

;; This simple plugin saves the lisp stumpwm::*input-history* to ~/.stumpwm.d/history and loads it again when starting StumpWM.
(load-module "command-history")

;; Implements a simple clipboard history (text only) manager by polling the clipboard selection periodically and keeping a stack of latest clippings.
(load-module "clipboard-history")
(define-key *root-map* (kbd "M-y") "show-clipboard-history")
;; start the polling timer process
(clipboard-history:start-clipboard-manager)
(setf clipboard-history:*clipboard-history-max-length* 100)


;; (load-module "productivity")
;; (define-key *top-map* (kbd "s-[") "productivity-mode-toggle")

(load-module "globalwindows")

;; swm-gaps
(load-module "swm-gaps")
;; Head gaps run along the 4 borders of the monitor(s)
(setf swm-gaps:*head-gaps-size* 0)

;; Inner gaps run along all the 4 borders of a window
(setf swm-gaps:*inner-gaps-size* 5)

;; Outer gaps add more padding to the outermost borders of a window (touching
;; the screen border)
(setf swm-gaps:*outer-gaps-size* 5)
;;(swm-gaps:toggle-gaps-on)


;; binwarp
;; (load-module "binwarp")
;; (binwarp:define-binwarp-mode nbl/binwarp-mode "X" (:map *root-map*)
;;   ((kbd "RET") "ratclick 1")
;;   ((kbd "SPC") "ratclick 3"))
;; (define-key *top-map* (kbd "s-SPC") "nbl/binwarp-mode")

;; urgent windows
;; [[file:modules/util/urgentwindows/README.org]]
(load-module "urgentwindows")
(setf urgentwindows:*urgent-window-message*
 "application ~a has just finished its business!")
(urgentwindows:raise-urgent)
