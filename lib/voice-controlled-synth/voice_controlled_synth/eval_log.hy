;; JSONL eval logger.
;;
;; One record per eval_hy call. Lives at
;;   ~/.local/share/voice-controlled-synth/eval-log.jsonl
;;
;; Record shape (see RFC §"Capture infrastructure"):
;;   {ts, session_id, session_turn, code, ok, value, stdout, stderr,
;;    error, latency_ms, hy_version, py_version}
;;
;; This file is the load-bearing artifact for Value Prop #4
;; (friction as research output). Keep the schema stable.

(import json os sys datetime uuid pathlib hy)

(setv default-log-path
      (.expanduser
       (pathlib.Path "~/.local/share/voice-controlled-synth/eval-log.jsonl")))

(defclass EvalLog []
  "Append-only JSONL writer scoped to one daemon session."

  (defn __init__ [self [path None]]
    (setv self.path (or path default-log-path))
    (.mkdir self.path.parent :parents True :exist-ok True)
    (setv self.session-id (. (uuid.uuid4) hex))
    (setv self.turn 0)
    (setv self.hy-version hy.__version__)
    (setv self.py-version (.join "." (lfor n (cut sys.version-info None 3) (str n)))))

  (defn record [self code ok value stdout stderr error latency-ms]
    "Append one record. Returns the dict written."
    (setv self.turn (+ self.turn 1))
    (setv row {"ts" (.isoformat (.now datetime.datetime datetime.timezone.utc))
                "session_id" self.session-id
                "session_turn" self.turn
                "code" code
                "ok" ok
                "value" value
                "stdout" stdout
                "stderr" stderr
                "error" error
                "latency_ms" latency-ms
                "hy_version" self.hy-version
                "py_version" self.py-version})
    (with [f (open self.path "a")]
      (.write f (json.dumps row :default str))
      (.write f "\n"))
    row))
