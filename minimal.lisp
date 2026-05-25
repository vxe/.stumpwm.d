(in-package :stumpwm)

;;;; Minimal emergency StumpWM config.
;;;; Loaded by F12 when the main init.lisp is broken.

;; Reset prefix to default C-t (does not require xmodmap)
(set-prefix-key (kbd "C-t"))

;; Try to restore Hyper key mapping (fails silently if xmodmap missing)
(ignore-errors (run-shell-command "xmodmap ~/.Xmodmap"))

;; F12 reloads this file (idempotent — safe to spam)
(define-key *top-map* (kbd "F12")
  "eval (load \"/home/vxe/.stumpwm.d/minimal.lisp\")")

;; Show cheatsheet — stays until first keypress
(let ((*timeout-wait* 600))
  (message "^B^1Minimal Emergency Config^n  (F12 reloads this)

^BPrefix^n  C-t  (or H-BackSpace if xmodmap active)

^BWindows^n  (prefix, then...)
  n / p      Next / prev window
  k          Close window (graceful)
  K          Kill app (force)
  w          Window list
  o          Other window
  '          Select window by name
  RET        Expose all windows
  0-9        Jump to window by number

^BFrames^n
  s          Split vertical (side by side)
  S          Split horizontal (top/bottom)
  R          Remove current frame
  Q          One frame only
  TAB / o    Next frame
  f          Select frame by number
  F          Show current frame number

^BCommands^n
  ;          Run StumpWM command
  :          Eval Lisp in StumpWM
  !          Run shell command
  h / ?      Help / show all bindings

^BGroups^n
  g          Groups submenu
  G          Visual group list
  F1-F10     Switch to group 1-10

^BRestore full config^n
  :  (load \"/home/vxe/.stumpwm.d/init.lisp\")"))
