;;;; tests/run-tests.lisp --- Simple Test Runner
;;;;
;;;; Simplified test runner that just checks if files load
;;;; Outputs to stdout for easy iteration

(in-package :stumpwm)

(defun test-file-loads (file)
  "Test if a file loads without errors"
  (handler-case
      (progn
        (load file)
        (format t "✓ ~A loaded successfully~%" file)
        t)
    (error (e)
      (format t "✗ ~A failed: ~A~%" file e)
      nil)))

(defun test-command-exists (cmd-name)
  "Test if a command exists"
  (if (fboundp cmd-name)
      (progn
        (format t "✓ Command ~A exists~%" cmd-name)
        t)
      (progn
        (format t "✗ Command ~A not found~%" cmd-name)
        nil)))

(defun test-keybinding-exists (key expected-command)
  "Test if a keybinding is set correctly"
  (let ((actual (lookup-key *top-map* (kbd key))))
    (if (equal actual expected-command)
        (progn
          (format t "✓ ~A -> ~A~%" key expected-command)
          t)
        (progn
          (format t "✗ ~A -> expected ~A, got ~A~%" key expected-command actual)
          nil))))

(defun run-stumpwm-tests-stdout ()
  "Run basic StumpWM configuration tests with stdout output"
  (format t "~%")
  (format t "=== StumpWM Configuration Tests ===~%")
  (format t "~%")
  (force-output)

  (let ((results '())
        (config-dir (truename "~/.stumpwm.d/")))

    ;; Test file loading (core.lisp is now merged into init.lisp)
    (format t "Testing file loads...~%")
    (push (test-file-loads (merge-pathnames "desktop/theme.lisp" config-dir)) results)
    (push (test-file-loads (merge-pathnames "desktop/formatters.lisp" config-dir)) results)
    (push (test-file-loads (merge-pathnames "desktop/keys.lisp" config-dir)) results)
    (format t "~%")

    ;; Test essential commands
    (format t "Testing commands...~%")
    (push (test-command-exists 'firefox-unity) results)
    (push (test-command-exists 'emacs) results)
    (push (test-command-exists 'kitty) results)
    (push (test-command-exists 'obs) results)
    (push (test-command-exists 'terminal) results)
    (format t "~%")

    ;; Test keybindings
    (format t "Testing keybindings...~%")
    (push (test-keybinding-exists "M-e" "emacs") results)
    (push (test-keybinding-exists "M-f" "firefox-unity") results)
    (push (test-keybinding-exists "M-t" "kitty") results)
    (push (test-keybinding-exists "M-o" "obs") results)
    (format t "~%")

    ;; Test prefix key
    (format t "Testing prefix key...~%")
    (let ((prefix (lookup-key *top-map* (kbd "M-DEL"))))
      (if (equal prefix '*root-map*)
          (progn
            (format t "✓ Prefix key set to M-DEL~%")
            (push t results))
          (progn
            (format t "✗ Prefix key is ~A, expected *ROOT-MAP*~%" prefix)
            (push nil results))))
    (format t "~%")

    ;; Test formatters
    (format t "Testing formatters...~%")
    (let ((dropbox-fmt (assoc #\D *screen-mode-line-formatters*)))
      (if dropbox-fmt
          (progn
            (format t "✓ Dropbox formatter registered~%")
            (push t results))
          (progn
            (format t "✗ Dropbox formatter not found~%")
            (push nil results))))
    (format t "~%")

    ;; Summary
    (let* ((total (length results))
           (passed (count t results))
           (failed (count nil results)))
      (format t "=== Test Results ===~%")
      (format t "Total: ~A  Passed: ~A  Failed: ~A~%" total passed failed)
      (format t "~%")
      (if (= failed 0)
          (format t "✅ All tests passed!~%")
          (format t "❌ Some tests failed~%"))
      (format t "~%")
      (force-output)
      (= failed 0))))

(defcommand run-stumpwm-tests () ()
  "Run basic StumpWM configuration tests (outputs to stdout)"
  (run-stumpwm-tests-stdout))

;;; run-tests.lisp ends here
