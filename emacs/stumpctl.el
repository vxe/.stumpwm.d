;;; stumpctl.el --- Control StumpWM from Emacs  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Vijay Edwin

;; Author: Vijay Edwin
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (sly "1.0.0"))
;; Keywords: tools, window-manager, stumpwm, lisp
;; URL: https://github.com/yourusername/stumpwm-claude

;;; Commentary:

;; This package provides Emacs commands to control StumpWM window manager
;; through a SLY connection. It allows you to send commands to StumpWM,
;; evaluate Lisp code in the StumpWM process, and integrate with the
;; Claude AI assistant.

;;; Code:

(require 'sly nil t)

;;;; Configuration

(defgroup stumpctl nil
  "Control StumpWM from Emacs."
  :group 'tools
  :prefix "stumpctl-")

(defcustom stumpctl-swank-port 4005
  "Port for Swank server running in StumpWM."
  :type 'integer
  :group 'stumpctl)

(defcustom stumpctl-swank-host "localhost"
  "Host for Swank server running in StumpWM."
  :type 'string
  :group 'stumpctl)

;;;; Connection Management

(defvar stumpctl--connection nil
  "The SLY connection to StumpWM.")

(defun stumpctl-connected-p ()
  "Check if connected to StumpWM via SLY."
  (and stumpctl--connection
       (sly-connected-p stumpctl--connection)))

(defun stumpctl-connect ()
  "Connect to StumpWM's Swank server."
  (interactive)
  (if (stumpctl-connected-p)
      (message "Already connected to StumpWM")
    (progn
      (message "Connecting to StumpWM on %s:%d..."
               stumpctl-swank-host stumpctl-swank-port)
      (sly-connect stumpctl-swank-host stumpctl-swank-port)
      (setq stumpctl--connection (sly-current-connection))
      (message "Connected to StumpWM!"))))

(defun stumpctl-disconnect ()
  "Disconnect from StumpWM's Swank server."
  (interactive)
  (when (stumpctl-connected-p)
    (sly-disconnect stumpctl--connection)
    (setq stumpctl--connection nil)
    (message "Disconnected from StumpWM")))

(defun stumpctl-ensure-connected ()
  "Ensure we're connected to StumpWM, connecting if necessary."
  (unless (stumpctl-connected-p)
    (stumpctl-connect))
  (stumpctl-connected-p))

;;;; Command Execution

(defun stumpctl-eval (code)
  "Evaluate CODE in StumpWM and return the result."
  (when (stumpctl-ensure-connected)
    (sly-eval `(cl:eval (cl:read-from-string ,code))
              stumpctl--connection)))

(defun stumpctl-eval-async (code &optional callback)
  "Evaluate CODE in StumpWM asynchronously.
If CALLBACK is provided, call it with the result."
  (when (stumpctl-ensure-connected)
    (sly-eval-async `(cl:eval (cl:read-from-string ,code))
                    callback
                    stumpctl--connection)))

(defun stumpctl-message (text)
  "Show a message in StumpWM."
  (stumpctl-eval (format "(stumpwm:message \"%s\")" text)))

(defun stumpctl-run-command (command)
  "Run a StumpWM command by name."
  (stumpctl-eval (format "(stumpwm:run-commands \"%s\")" command)))

;;;; Interactive Commands

;;;###autoload
(defun stumpctl-send-command (command)
  "Send COMMAND to StumpWM."
  (interactive "sStumpWM command: ")
  (stumpctl-run-command command)
  (message "Sent command to StumpWM: %s" command))

;;;###autoload
(defun stumpctl-eval-region (start end)
  "Evaluate the region from START to END in StumpWM."
  (interactive "r")
  (let ((code (buffer-substring-no-properties start end)))
    (stumpctl-eval-async code
                         (lambda (result)
                           (message "StumpWM result: %s" result)))))

;;;###autoload
(defun stumpctl-eval-buffer ()
  "Evaluate the entire buffer in StumpWM."
  (interactive)
  (stumpctl-eval-region (point-min) (point-max)))

;;;###autoload
(defun stumpctl-eval-defun ()
  "Evaluate the top-level form around point in StumpWM."
  (interactive)
  (save-excursion
    (end-of-defun)
    (let ((end (point)))
      (beginning-of-defun)
      (stumpctl-eval-region (point) end))))

;;;; Window Management Commands

;;;###autoload
(defun stumpctl-switch-group (group-name)
  "Switch to GROUP-NAME in StumpWM."
  (interactive "sGroup name: ")
  (stumpctl-eval (format "(stumpwm:gselect \"%s\")" group-name))
  (message "Switched to group: %s" group-name))

;;;###autoload
(defun stumpctl-move-window-to-group (group-name)
  "Move current window to GROUP-NAME."
  (interactive "sMove to group: ")
  (stumpctl-eval (format "(stumpwm:gmove \"%s\")" group-name))
  (message "Moved window to group: %s" group-name))

;;;###autoload
(defun stumpctl-hsplit ()
  "Split current frame horizontally in StumpWM."
  (interactive)
  (stumpctl-run-command "hsplit"))

;;;###autoload
(defun stumpctl-vsplit ()
  "Split current frame vertically in StumpWM."
  (interactive)
  (stumpctl-run-command "vsplit"))

;;;###autoload
(defun stumpctl-balance-frames ()
  "Balance all frames in current group."
  (interactive)
  (stumpctl-eval "(stumpwm:balance-frames)")
  (message "Frames balanced"))

;;;###autoload
(defun stumpctl-reload-config ()
  "Reload StumpWM configuration."
  (interactive)
  (stumpctl-eval "(stumpwm:reload)")
  (message "StumpWM configuration reloaded"))

;;;; Workspace Queries

;;;###autoload
(defun stumpctl-list-groups ()
  "List all StumpWM groups (workspaces)."
  (interactive)
  (stumpctl-eval-async
   "(mapcar #'stumpwm:group-name (stumpwm:screen-groups (stumpwm:current-screen)))"
   (lambda (groups)
     (message "Groups: %s" groups))))

;;;###autoload
(defun stumpctl-list-windows ()
  "List all windows in current group."
  (interactive)
  (stumpctl-eval-async
   "(mapcar (lambda (w) (list (stumpwm:window-class w) (stumpwm:window-title w)))
            (stumpwm:group-windows (stumpwm:current-group)))"
   (lambda (windows)
     (message "Windows: %s" windows))))

;;;; Convenience Functions

;;;###autoload
(defun stumpctl-emacs-to-front ()
  "Bring Emacs window to front in StumpWM."
  (interactive)
  (stumpctl-eval "(stumpwm:pull-hidden-other)"))

;;;###autoload
(defun stumpctl-terminal ()
  "Launch terminal in StumpWM."
  (interactive)
  (stumpctl-run-command "terminal"))

;;;###autoload
(defun stumpctl-browser ()
  "Launch browser in StumpWM."
  (interactive)
  (stumpctl-run-command "browser"))

;;;; Mode

(defvar stumpctl-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c s c") 'stumpctl-connect)
    (define-key map (kbd "C-c s d") 'stumpctl-disconnect)
    (define-key map (kbd "C-c s e") 'stumpctl-eval-defun)
    (define-key map (kbd "C-c s r") 'stumpctl-eval-region)
    (define-key map (kbd "C-c s b") 'stumpctl-eval-buffer)
    (define-key map (kbd "C-c s g") 'stumpctl-switch-group)
    (define-key map (kbd "C-c s m") 'stumpctl-move-window-to-group)
    (define-key map (kbd "C-c s s") 'stumpctl-send-command)
    (define-key map (kbd "C-c s h") 'stumpctl-hsplit)
    (define-key map (kbd "C-c s v") 'stumpctl-vsplit)
    (define-key map (kbd "C-c s =") 'stumpctl-balance-frames)
    (define-key map (kbd "C-c s R") 'stumpctl-reload-config)
    map)
  "Keymap for `stumpctl-mode'.")

;;;###autoload
(define-minor-mode stumpctl-mode
  "Minor mode for controlling StumpWM from Emacs."
  :lighter " StumpCtl"
  :keymap stumpctl-mode-map
  :group 'stumpctl
  (if stumpctl-mode
      (message "StumpWM control mode enabled")
    (message "StumpWM control mode disabled")))

;;;; Auto-connect

(defcustom stumpctl-auto-connect t
  "Automatically connect to StumpWM when stumpctl-mode is enabled."
  :type 'boolean
  :group 'stumpctl)

(when stumpctl-auto-connect
  (add-hook 'stumpctl-mode-hook 'stumpctl-connect))

(provide 'stumpctl)
;;; stumpctl.el ends here
