;; daemon.hy — Claude SDK client loop for the voice-controlled synth.
;;
;; Long-running ClaudeSDKClient. One persistent session: every
;; transcript routed through here adds to the same context, so the
;; model accumulates state across turns (Value Prop #2).
;;
;; Two input modes:
;;   stdin  — one prompt per line, for deterministic testing
;;   http   — POST /say { "text": "…" } returns the model's reply
;;            (planned for whisper-clip → daemon integration)

(import os sys asyncio pathlib argparse json signal)
(import claude_agent_sdk :as cas)
(import voice_controlled_synth.tools :as tools)
(import voice_controlled_synth.eval_log :as eval-log-mod)

(setv PRIMER-PATH
      (.joinpath (pathlib.Path __file__) ".." ".." "primer-hy.md"))

(defn read-primer []
  "Read the Hy primer markdown as the system prompt."
  (setv p (.resolve PRIMER-PATH))
  (if (.exists p)
      (.read_text p)
      "You are a live-coding musician. You use the eval_hy tool to evaluate Hy code against a persistent world."))

(defn build-options [mcp-server]
  "Return a ClaudeAgentOptions with our MCP server + restricted toolset
   + the Hy primer as system prompt."
  (cas.ClaudeAgentOptions
    :system-prompt (read-primer)
    :mcp-servers {"vcs" mcp-server}
    :allowed-tools ["mcp__vcs__eval_hy" "mcp__vcs__state_dump"]
    :max-turns 12))

(defclass Daemon []

  (defn __init__ [self]
    (setv self.log (eval-log-mod.EvalLog))
    (setv self.mcp-server (tools.build-server self.log))
    (setv self.options (build-options self.mcp-server))
    (setv self.client (cas.ClaudeSDKClient :options self.options))
    (setv self.session-turn 0))

  (defn :async start [self]
    (await (.connect self.client))
    (print (.format "[daemon] connected. session_id={}" self.log.session-id)
           :file sys.stderr :flush True))

  (defn :async stop [self]
    (await (.disconnect self.client))
    (print "[daemon] disconnected." :file sys.stderr :flush True))

  (defn :async ask [self prompt]
    "Send PROMPT to the model; stream messages; return final result text."
    (setv self.session-turn (+ self.session-turn 1))
    (print (.format "\n── turn {} ── user: {}" self.session-turn prompt)
           :file sys.stderr :flush True)
    (await (.query self.client :prompt prompt))
    (setv final-text "")
    (setv tool-uses [])
    (for [:async msg (.receive_response self.client)]
      (cond
        (isinstance msg cas.AssistantMessage)
          (for [block msg.content]
            (cond
              (isinstance block cas.TextBlock)
                (do
                  (setv final-text block.text)
                  (print (.format "  ai: {}" block.text)
                         :file sys.stderr :flush True))
              (isinstance block cas.ToolUseBlock)
                (do
                  (.append tool-uses {"name" block.name "input" block.input})
                  (print (.format "  tool_use: {} {}" block.name block.input)
                         :file sys.stderr :flush True))))
        (isinstance msg cas.ResultMessage)
          (print (.format "  result: cost=${:.4f} subtype={}"
                          (or (getattr msg "total_cost_usd" None) 0)
                          msg.subtype)
                 :file sys.stderr :flush True)))
    {"text" final-text "tool_uses" tool-uses "turn" self.session-turn}))

;; ── stdin mode ───────────────────────────────────────────────────────

(defn :async run-stdin [daemon]
  "Read one prompt per line from stdin. Each line → one ask."
  (await (.start daemon))
  (print "[daemon] stdin mode — type a prompt and hit enter. Ctrl-D to exit." :file sys.stderr :flush True)
  (try
    (while True
      (try
        (setv line (await (.run_in_executor (asyncio.get_event_loop) None input "")))
        (except [EOFError]
          (break)))
      (setv line (.strip line))
      (when line
        (await (.ask daemon line))))
    (finally
      (await (.stop daemon)))))

;; ── http mode ────────────────────────────────────────────────────────

(defn :async run-http [daemon port]
  "POST /say {\"text\": \"…\"} → returns {\"text\": ..., \"tool_uses\": ..., \"turn\": ...}.
   GET /healthz → returns {\"ok\": true, \"session_id\": ..., \"turn\": ...}."
  (import aiohttp.web :as aweb)
  (await (.start daemon))
  (defn :async healthz [request]
    (aweb.json_response
      {"ok" True
       "session_id" daemon.log.session-id
       "turn" daemon.session-turn}))
  (defn :async say [request]
    (setv body (await (.json request)))
    (setv text (.get body "text" ""))
    (when (not text)
      (return (aweb.json_response {"error" "missing 'text'"} :status 400)))
    (setv reply (await (.ask daemon text)))
    (aweb.json_response reply))
  (setv app (aweb.Application))
  (.add_routes app.router
               [(aweb.get "/healthz" healthz)
                (aweb.post "/say" say)])
  (setv runner (aweb.AppRunner app))
  (await (.setup runner))
  (setv site (aweb.TCPSite runner "127.0.0.1" port))
  (await (.start site))
  (print (.format "[daemon] http mode — listening on http://127.0.0.1:{}" port)
         :file sys.stderr :flush True)
  (try
    ;; sleep forever
    (await (asyncio.Event.wait (asyncio.Event)))
    (finally
      (await (.cleanup runner))
      (await (.stop daemon)))))

;; ── entry ────────────────────────────────────────────────────────────

(defn parse-args []
  (setv ap (argparse.ArgumentParser :prog "voice-controlled-synth"))
  (.add_argument ap "--http" :type int :default None
                 :help "HTTP server port (default: stdin mode)")
  (.parse_args ap))

(defn :async amain []
  (setv args (parse-args))
  (setv daemon (Daemon))
  (if (is-not args.http None)
      (await (run-http daemon args.http))
      (await (run-stdin daemon))))

(defn main []
  (try
    (asyncio.run (amain))
    (except [KeyboardInterrupt]
      (print "\n[daemon] interrupted." :file sys.stderr :flush True))))
