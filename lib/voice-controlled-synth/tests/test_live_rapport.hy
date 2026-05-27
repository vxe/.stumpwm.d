;; tests/test_live_rapport.hy — live SDK two-turn test (Value Prop #2).
;;
;; Cost: ~$0.50-$1.00 per run depending on how iterative Claude is.
;; Run with: ./venv/bin/python -c "import hy; import tests.test_live_rapport"
;;
;; Turn 1: define `secret` = 42 via eval_hy, confirm via state_dump.
;; Turn 2: ask for secret * 2 — model must remember `secret` from turn 1.
;;
;; Success criteria:
;;   - Both turns appear in the JSONL log
;;   - Turn 2's code references `secret` (proves persistence was used)
;;   - Final reply contains "84"

(import os sys asyncio json pathlib)
(import voice_controlled_synth.daemon :as dmn)

(defn :async run []
  (setv d (dmn.Daemon))
  (try
    (await (.start d))
    (print "\n══════════ TURN 1 ══════════" :flush True)
    (setv r1 (await (.ask d
      "Use the eval_hy tool to evaluate (setv secret 42), then call state_dump to confirm `secret` is in defined_names. Reply with just the word OK when done.")))
    (print "\n══════════ TURN 2 ══════════" :flush True)
    (setv r2 (await (.ask d
      "Use eval_hy to compute (* secret 2). Reply with just the number.")))
    (print "\n══════════ ASSERTIONS ══════════" :flush True)
    (setv t1 (get r1 "text"))
    (setv t2 (get r2 "text"))
    (setv tu2 (get r2 "tool_uses"))
    (print (.format "turn1 text: {}" t1) :flush True)
    (print (.format "turn2 text: {}" t2) :flush True)
    (print (.format "turn2 tool_uses: {}" tu2) :flush True)
    (setv turn2-code "")
    (for [tu tu2]
      (when (= (get tu "name") "mcp__vcs__eval_hy")
        (setv turn2-code (+ turn2-code " " (.get (get tu "input") "code" "")))))
    (setv passed-secret-ref (in "secret" turn2-code))
    (setv passed-result-84 (in "84" t2))
    (print (.format "\nASSERT turn2 code mentions 'secret': {}" passed-secret-ref) :flush True)
    (print (.format "       turn2 reply contains '84':      {}" passed-result-84) :flush True)
    (when (and passed-secret-ref passed-result-84)
      (print "\n✓ STATEFUL RAPPORT VERIFIED  (Value Prop #2)" :flush True))
    (when (not (and passed-secret-ref passed-result-84))
      (print "\n✗ Some assertions failed — inspect JSONL log for the actual code Claude wrote" :flush True))
    (finally
      (await (.stop d)))))

(asyncio.run (run))
