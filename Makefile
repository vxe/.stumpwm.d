# Makefile for StumpWM Configuration Testing and Management

.PHONY: help test test-fiveam test-simple clean reload restart backup

# Default target
help:
	@echo "StumpWM Configuration Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  make test         - Run simple interactive tests"
	@echo "  make test-fiveam  - Run comprehensive FiveAM test suite"
	@echo "  make test-simple  - Run simple test runner (same as 'make test')"
	@echo "  make reload       - Reload StumpWM configuration"
	@echo "  make restart      - Restart StumpWM"
	@echo "  make backup       - Backup current configuration to /tmp"
	@echo "  make clean        - Clean test artifacts"
	@echo ""

# Run simple tests (default test target)
test: test-simple

# Run simple test runner
test-simple:
	@~/.stumpwm.d/bin/test-runner.sh

# Run FiveAM comprehensive test suite
test-fiveam:
	@echo "Running FiveAM test suite..."
	@stumpwm-eval "(progn \
	  (load \"~/.stumpwm.d/tests/config-tests.lisp\") \
	  (let ((results (stumpwm-config-tests:run-config-tests))) \
	    (if results \
	        (format t \"~%✓ All tests passed!~%\") \
	        (format t \"~%✗ Some tests failed~%\"))))" 2>&1

# Reload StumpWM configuration
reload:
	@echo "Reloading StumpWM configuration..."
	@stumpwm-eval "(loadrc)"
	@echo "✓ Configuration reloaded"

# Restart StumpWM
restart:
	@echo "Restarting StumpWM..."
	@stumpwm-eval "(restart-hard)"

# Backup configuration to /tmp
backup:
	@echo "Backing up configuration to /tmp..."
	@timestamp=$$(date +%Y%m%d_%H%M%S) && \
	cp -r ~/.stumpwm.d /tmp/stumpwm-backup-$$timestamp && \
	echo "✓ Backup saved to /tmp/stumpwm-backup-$$timestamp"

# Clean test artifacts
clean:
	@echo "Cleaning test artifacts..."
	@rm -f ~/.stumpwm.d/**/*.fasl
	@rm -f ~/.stumpwm.d/**/*~
	@echo "✓ Clean complete"

# Reload and test
reload-test: reload
	@sleep 1
	@$(MAKE) test

# Full check: reload, test, verify
check: reload-test
	@echo ""
	@echo "Configuration check complete!"
