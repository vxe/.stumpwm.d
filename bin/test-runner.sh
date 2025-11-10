#!/bin/bash
# test-runner.sh - Run StumpWM tests with proper output

# Use stumpish if available, otherwise stumpwm-eval
if command -v stumpish &> /dev/null; then
    stumpish eval "(progn (load \"~/.stumpwm.d/tests/run-tests.lisp\") (stumpwm::run-stumpwm-tests-stdout))"
else
    # Fallback to using stumpwm-eval and redirecting to a temp file
    TMPOUT=$(mktemp /tmp/stumpwm-test-output.XXXXXX)

    # Run the test
    stumpwm-eval "(progn \
      (load \"~/.stumpwm.d/tests/run-tests.lisp\") \
      (with-open-file (out \"$TMPOUT\" :direction :output :if-exists :supersede) \
        (let ((*standard-output* out)) \
          (stumpwm::run-stumpwm-tests-stdout))))" > /dev/null 2>&1

    # Display the output
    cat "$TMPOUT"
    rm -f "$TMPOUT"
fi
