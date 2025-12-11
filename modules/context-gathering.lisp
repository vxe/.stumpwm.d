;;;; modules/context-gathering.lisp --- Context Gathering for Claude
;;;;
;;;; Collects information about the current desktop state (windows, groups,
;;;; focus, etc.) to provide rich context to Claude for better responses.
;;;;

(in-package :stumpwm-user)

;;;; ===========================================================================
;;;; Context Collection Functions
;;;; ===========================================================================

(defun gather-window-context ()
  "Gather information about the current window."
  (let ((win (current-window)))
    (if win
        (list :has_window t
              :class (window-class win)
              :title (window-title win)
              :type (window-type win)
              :width (window-width win)
              :height (window-height win))
        (list :has_window nil))))

(defun gather-group-context ()
  "Gather information about the current workspace/group."
  (let* ((group (current-group))
         (windows (group-windows group)))
    (list :name (group-name group)
          :number (group-number group)
          :window_count (length windows)
          :windows (mapcar (lambda (w)
                            (list :class (window-class w)
                                  :title (window-title w)))
                          windows))))

(defun gather-all-groups-context ()
  "Gather information about all workspaces/groups."
  (let ((groups (screen-groups (current-screen))))
    (mapcar (lambda (g)
             (list :name (group-name g)
                   :number (group-number g)
                   :window_count (length (group-windows g))
                   :current (eq g (current-group))))
           groups)))

(defun gather-frame-context ()
  "Gather information about frames (splits) in current group."
  (let* ((group (current-group))
         (frame (tile-group-current-frame group)))
    (list :frame_number (frame-number frame)
          :x (frame-x frame)
          :y (frame-y frame)
          :width (frame-width frame)
          :height (frame-height frame))))

(defun gather-system-context ()
  "Gather basic system information."
  (list :hostname (machine-instance)
        :os (software-type)
        :lisp_implementation (lisp-implementation-type)
        :lisp_version (lisp-implementation-version)
        :time (format-timestamp)))

(defun gather-mode-line-context ()
  "Gather information about mode line state."
  (let ((head (current-head)))
    (list :enabled (if (head-mode-line head) t nil)
          :format *screen-mode-line-format*)))

;;;; ===========================================================================
;;;; Full Context Assembly
;;;; ===========================================================================

(defun gather-full-context (&key
                            (include-window *claude-include-window-titles*)
                            (include-group *claude-include-group-info*)
                            (include-system *claude-include-system-info*))
  "Gather complete context about the current desktop state.
   Returns a property list with all relevant information."
  (let ((context nil))

    ;; Current window
    (when include-window
      (setf context (append context
                           (list :current_window (gather-window-context)))))

    ;; Current group/workspace
    (when include-group
      (setf context (append context
                           (list :current_group (gather-group-context)
                                :all_groups (gather-all-groups-context)))))

    ;; Frame information
    (safely
      (setf context (append context
                           (list :frame (gather-frame-context)))))

    ;; System information
    (when include-system
      (setf context (append context
                           (list :system (gather-system-context)))))

    ;; Mode line state
    (setf context (append context
                         (list :mode_line (gather-mode-line-context))))

    context))

;;;; ===========================================================================
;;;; Context Formatting for Claude
;;;; ===========================================================================

(defun format-context-for-claude (context)
  "Format CONTEXT as a human-readable string for Claude."
  (with-output-to-string (out)
    (format out "Current Desktop State:~%~%")

    ;; Current window
    (let ((window (getf context :current_window)))
      (if (getf window :has_window)
          (format out "Focused Window:~%")
          (format out "No window currently focused.~%"))
      (when (getf window :has_window)
        (format out "  Class: ~A~%" (getf window :class))
        (format out "  Title: ~A~%" (getf window :title))
        (format out "  Size: ~Ax~A~%~%"
               (getf window :width)
               (getf window :height))))

    ;; Current group
    (let ((group (getf context :current_group)))
      (when group
        (format out "Current Workspace:~%")
        (format out "  Name: ~A~%" (getf group :name))
        (format out "  Windows: ~A~%~%" (getf group :window_count))))

    ;; All groups
    (let ((groups (getf context :all_groups)))
      (when groups
        (format out "All Workspaces:~%")
        (dolist (g groups)
          (format out "  ~A~A (windows: ~A)~%"
                 (if (getf g :current) "*" " ")
                 (getf g :name)
                 (getf g :window_count)))
        (format out "~%")))

    ;; Frame info
    (let ((frame (getf context :frame)))
      (when frame
        (format out "Current Frame: #~A (~Ax~A)~%~%"
               (getf frame :frame_number)
               (getf frame :width)
               (getf frame :height))))

    ;; System info
    (let ((system (getf context :system)))
      (when system
        (format out "System:~%")
        (format out "  Host: ~A~%" (getf system :hostname))
        (format out "  Time: ~A~%~%" (getf system :time))))

    (format out "---~%~%")
    (format out "You are controlling a StumpWM window manager. ")
    (format out "You can execute Lisp code to manipulate windows, groups, and frames. ")
    (format out "Available functions include: stumpwm:run-commands, stumpwm:message, ")
    (format out "stumpwm:move-window-to-group, stumpwm:switch-to-group, and more.")))

;;;; ===========================================================================
;;;; Quick Context Queries
;;;; ===========================================================================

(defun get-window-list-string ()
  "Get a simple string listing all windows."
  (let ((windows (get-all-windows)))
    (if windows
        (format nil "~{~A~^, ~}"
               (mapcar (lambda (w)
                        (format nil "~A (~A)"
                               (window-title w)
                               (window-class w)))
                      windows))
        "No windows")))

(defun get-group-list-string ()
  "Get a simple string listing all groups."
  (let ((groups (screen-groups (current-screen))))
    (format nil "~{~A~^, ~}"
           (mapcar (lambda (g)
                    (format nil "~A~A"
                           (if (eq g (current-group)) "*" "")
                           (group-name g)))
                  groups))))

;;;; ===========================================================================
;;;; Commands
;;;; ===========================================================================

(defcommand claude-context () ()
  "Show the current context that would be sent to Claude."
  (let* ((context (gather-full-context))
         (formatted (format-context-for-claude context)))
    (message formatted)))

(defcommand show-windows () ()
  "Show a list of all windows."
  (message (get-window-list-string)))

(defcommand show-groups () ()
  "Show a list of all groups."
  (message (get-group-list-string)))

;;;; ===========================================================================
;;;; Testing
;;;; ===========================================================================

(defun test-context-gathering ()
  "Test context gathering and display the result."
  (let* ((context (gather-full-context :include-system t))
         (formatted (format-context-for-claude context)))
    (message formatted)
    (log-info "Context gathering test completed")
    formatted))

;;; context-gathering.lisp ends here
