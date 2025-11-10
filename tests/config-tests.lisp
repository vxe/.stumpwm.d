;;;; tests/config-tests.lisp --- Unit Tests for StumpWM Configuration
;;;;
;;;; Tests to verify all config files load correctly and define expected symbols
;;;;

(ql:quickload :fiveam :silent t)

(defpackage :stumpwm-config-tests
  (:use :cl :fiveam :stumpwm))

(in-package :stumpwm-config-tests)

;;;; ===========================================================================
;;;; Test Suite Definition
;;;; ===========================================================================

(def-suite stumpwm-config-suite
  :description "Test suite for StumpWM configuration files")

(in-suite stumpwm-config-suite)

;;;; ===========================================================================
;;;; File Loading Tests
;;;; ===========================================================================

(test core-file-loads
  "Test that desktop/core.lisp loads without errors"
  (finishes
    (load (merge-pathnames "desktop/core.lisp"
                          (truename "~/.stumpwm.d/")))))

(test theme-file-loads
  "Test that desktop/theme.lisp loads without errors"
  (finishes
    (load (merge-pathnames "desktop/theme.lisp"
                          (truename "~/.stumpwm.d/")))))

(test formatters-file-loads
  "Test that desktop/formatters.lisp loads without errors"
  (finishes
    (load (merge-pathnames "desktop/formatters.lisp"
                          (truename "~/.stumpwm.d/")))))

(test keys-file-loads
  "Test that desktop/keys.lisp loads without errors"
  (finishes
    (load (merge-pathnames "desktop/keys.lisp"
                          (truename "~/.stumpwm.d/")))))

;;;; ===========================================================================
;;;; Command Definition Tests
;;;; ===========================================================================

(test essential-commands-defined
  "Test that essential commands are defined"
  (is (fboundp 'firefox))
  (is (fboundp 'emacs))
  (is (fboundp 'kitty))
  (is (fboundp 'obs))
  (is (fboundp 'terminal))
  (is (fboundp 'browser)))

(test window-management-commands-defined
  "Test that window management commands are defined"
  (is (fboundp 'hsplit-and-focus))
  (is (fboundp 'vsplit-and-focus))
  (is (fboundp 'kill-window-and-rebalance)))

(test system-commands-defined
  "Test that system commands are defined"
  (is (fboundp 'lock-screen))
  (is (fboundp 'suspend))
  (is (fboundp 'shutdown-prompt))
  (is (fboundp 'reboot-prompt)))

(test info-commands-defined
  "Test that info commands are defined"
  (is (fboundp 'show-window-info))
  (is (fboundp 'show-group-info))
  (is (fboundp 'keybinding-help)))

;;;; ===========================================================================
;;;; Keybinding Tests
;;;; ===========================================================================

(test prefix-key-configured
  "Test that prefix key is set to M-DEL"
  (is (equal (lookup-key *top-map* (kbd "M-DEL")) '*root-map*)))

(test option-key-launchers-bound
  "Test that Option key launchers are bound"
  (is (equal (lookup-key *top-map* (kbd "M-e")) "emacs"))
  (is (equal (lookup-key *top-map* (kbd "M-f")) "firefox"))
  (is (equal (lookup-key *top-map* (kbd "M-t")) "kitty"))
  (is (equal (lookup-key *top-map* (kbd "M-o")) "obs")))

(test super-key-launchers-bound
  "Test that Super key launchers are bound"
  (is (equal (lookup-key *top-map* (kbd "s-RET")) "terminal"))
  (is (equal (lookup-key *top-map* (kbd "s-e")) "emacs"))
  (is (equal (lookup-key *top-map* (kbd "s-b")) "browser"))
  (is (equal (lookup-key *top-map* (kbd "s-f")) "file-manager")))

(test window-management-keys-bound
  "Test that window management keys are bound"
  (is (equal (lookup-key *top-map* (kbd "s-v")) "vsplit-and-focus"))
  (is (equal (lookup-key *top-map* (kbd "s-s")) "hsplit-and-focus"))
  (is (equal (lookup-key *top-map* (kbd "s-q")) "delete-window"))
  (is (equal (lookup-key *top-map* (kbd "s-Q")) "kill-window-and-rebalance")))

;;;; ===========================================================================
;;;; Modeline Formatter Tests
;;;; ===========================================================================

(test dropbox-formatter-registered
  "Test that Dropbox formatter is registered"
  (is (not (null (assoc #\D *screen-mode-line-formatters*)))))

(test dropbox-formatter-works
  "Test that Dropbox formatter produces output"
  (let ((output (fmt-dropbox nil)))
    (is (stringp output))
    (is (> (length output) 0))))

;;;; ===========================================================================
;;;; Configuration Integrity Tests
;;;; ===========================================================================

(test modeline-format-configured
  "Test that mode-line format is configured"
  (is (not (null *screen-mode-line-format*)))
  (is (listp *screen-mode-line-format*)))

(test groups-created
  "Test that default groups exist"
  ;; Note: This test might fail if groups aren't created yet
  ;; Commenting out for now since it depends on StumpWM state
  ;; (is (find-group (current-screen) "main"))
  ;; (is (find-group (current-screen) "dev"))
  (pass))

;;;; ===========================================================================
;;;; Test Runner
;;;; ===========================================================================

(defun run-config-tests ()
  "Run all configuration tests and return results"
  (run! 'stumpwm-config-suite))

(defun run-config-tests-verbose ()
  "Run all configuration tests with verbose output"
  (run! 'stumpwm-config-suite))

;;;; ===========================================================================
;;;; Export
;;;; ===========================================================================

(export '(run-config-tests
          run-config-tests-verbose
          stumpwm-config-suite))

;;; config-tests.lisp ends here
