;; tools.hy — claude_agent_sdk @tool functions.
;;
;; Two tools today:
;;   eval_hy(code) — compiles + evals Hy against world.__dict__
;;                   (persistent across turns). Logs every call to JSONL.
;;   state_dump()  — defined names, server status, bpm.
;;
;; build-server(eval-log) returns an SDK MCP server dict, suitable
;; for ClaudeAgentOptions.mcp_servers["vcs"].

(import contextlib io traceback time hy)
(import claude_agent_sdk :as cas)
(import voice_controlled_synth.world :as world)

(setv MAX-REPR 2000)

(defn safe-repr [value]
  "repr(value), clamped so huge objects don't blow the tool output."
  (try
    (setv s (repr value))
    (if (> (len s) MAX-REPR)
        (+ (cut s None MAX-REPR) "  …[truncated]")
        s)
    (except [e Exception]
      (.format "<unrepresentable: {}>" e))))

(defn eval-hy-impl [code]
  "Compile + eval CODE against world.__dict__. Returns a dict with
   ok / value / stdout / stderr / error / latency-ms keys."
  (setv buf-out (io.StringIO))
  (setv buf-err (io.StringIO))
  (setv t0 (time.perf_counter))
  (setv ok True)
  (setv value None)
  (setv error None)
  (try
    (with [_ (contextlib.redirect_stdout buf-out)
           _ (contextlib.redirect_stderr buf-err)]
      (for [form (hy.read_many code)]
        (setv value (hy.eval form world.__dict__))))
    (except [e Exception]
      (setv ok False)
      (setv error (.format "{}: {}\n{}"
                            (. (type e) __name__)
                            (str e)
                            (traceback.format_exc)))))
  (setv latency-ms (* 1000 (- (time.perf_counter) t0)))
  {"ok" ok
   "value" (if ok (safe-repr value) None)
   "stdout" (.getvalue buf-out)
   "stderr" (.getvalue buf-err)
   "error" error
   "latency_ms" latency-ms})

(defn format-result [r]
  "Render a tool-call result dict as the text block Claude sees."
  (if (get r "ok")
      (.join "\n"
        ["ok"
         (.format "value: {}" (get r "value"))
         (.format "stdout: {}" (get r "stdout"))
         (.format "stderr: {}" (get r "stderr"))
         (.format "latency_ms: {:.2f}" (get r "latency_ms"))])
      (.join "\n"
        ["FAIL"
         (.format "error:\n{}" (get r "error"))
         (.format "stdout: {}" (get r "stdout"))
         (.format "stderr: {}" (get r "stderr"))
         (.format "latency_ms: {:.2f}" (get r "latency_ms"))])))

;; ── @tool wrappers — bound to a specific EvalLog instance ────────────

(defn make-eval-hy [log]
  "Return an @tool-decorated function bound to LOG (an EvalLog instance)."
  (defn :async eval-hy-tool [args]
    (setv code (get args "code"))
    (setv r (eval-hy-impl code))
    (.record log
             code
             (get r "ok")
             (get r "value")
             (get r "stdout")
             (get r "stderr")
             (get r "error")
             (get r "latency_ms"))
    {"content" [{"type" "text" "text" (format-result r)}]})
  ((cas.tool "eval_hy"
              (.join "\n"
                ["Evaluate a Hy expression against the persistent live-coding"
                 "world. State persists across calls — variables, defns, and"
                 "synths defined in turn N are still available in turn N+1."
                 "Returns ok/value/stdout/stderr/error/latency_ms."])
              {"code" str})
   eval-hy-tool))

(defn state-dump-impl []
  "Return a dict summarising the current world state."
  {"defined_names" (sorted (world.defined-names))
   "bpm" world.bpm
   "server_connected" (is-not world.server None)
   "default_port" world.default-port})

(defn make-state-dump []
  (defn :async state-dump-tool [args]
    (import json)
    (setv s (state-dump-impl))
    {"content" [{"type" "text"
                 "text" (json.dumps s :indent 2 :default str)}]})
  ((cas.tool "state_dump"
              "Return the current live-coding world: defined names, current bpm, server status."
              {})
   state-dump-tool))

;; ── SDK MCP server builder ───────────────────────────────────────────

(defn build-server [log]
  "Build an SDK MCP server dict for ClaudeAgentOptions.mcp_servers.
   LOG is an EvalLog instance shared across calls."
  (cas.create-sdk-mcp-server
    :name "vcs"
    :tools [(make-eval-hy log) (make-state-dump)]))
