;; world.hy — persistent globals for the live-coding agent.
;;
;; This module's __dict__ IS the namespace Claude's eval_hy code runs
;; against. Top-level (defn …) / (setv …) here become preloaded
;; names visible to the model on every turn.
;;
;; When the model writes `(setv x 5)` in an eval, that mutation lands
;; in world.__dict__ and survives to the next turn. That's how Value
;; Prop #2 (stateful live-coding rapport) actually works.

(import math)
(import supriya)
(import pythonosc.udp_client :as osc-client)
(import pythonosc.osc_message_builder :as osc-msg)

;; ── State (mutable across turns) ─────────────────────────────────────

;; supriya Server, lazy. None until (connect-server) is called.
(setv server None)

;; Raw python-osc client for low-level messages (e.g. /g_freeAll).
;; Set alongside `server` by (connect-server).
(setv osc None)

;; Current tempo. Read by patterns; mutable across turns.
(setv bpm 120)

(setv default-port 57110)

;; ── Helpers Claude can call directly ─────────────────────────────────

(defn note-to-hz [n]
  "MIDI note number → frequency in Hz. Middle C = 60 ≈ 261.63."
  (* 440.0 (** 2 (/ (- n 69) 12))))

(defn connect-server [[port default-port]]
  "Connect supriya to an existing scsynth on PORT. Sets `server` + `osc`."
  (global server osc)
  (setv server (supriya.Server))
  (.connect server :port port)
  (setv osc (osc-client.SimpleUDPClient "127.0.0.1" port))
  server)

(defn boot-server [[port default-port]]
  "Boot a new scsynth subprocess on PORT. Sets `server` + `osc`.
  Prefer (connect-server) if cl-collider has already booted one."
  (global server osc)
  (setv server (supriya.Server))
  (.boot server :port port)
  (setv osc (osc-client.SimpleUDPClient "127.0.0.1" port))
  server)

(defn panic []
  "Free every node on the running scsynth. Outside-the-agent path
  for this is panic.sh at the project root."
  (when osc
    (.send_message osc "/g_freeAll" [0]))
  "panic sent")

(defn defined-names []
  "List the top-level names currently in the world namespace —
  excluding dunders and modules. Used by state_dump."
  (import types)
  (lfor [k v] (.items (globals))
        :if (and (not (.startswith k "_"))
                 (not (isinstance v types.ModuleType)))
        k))
