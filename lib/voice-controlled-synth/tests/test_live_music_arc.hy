;; tests/test_live_music_arc.hy — a more realistic 4-turn music-coding arc.
;;
;; Goal: populate the JSONL with substantive content so analyze_eval_log
;; has real material. Each turn extends the previous turn's state —
;; another demonstration of Value Prop #2 in the music domain.
;;
;; Cost estimate: ~$1.50 per run.

(import os sys asyncio)
(import voice_controlled_synth.daemon :as dmn)

(defn :async run []
  (setv d (dmn.Daemon))
  (try
    (await (.start d))
    (print "\n══════════ TURN 1: define helper ══════════" :flush True)
    (await (.ask d
      "Define a Hy function called `chord-hz` that takes a root MIDI note number and returns a list of three frequencies forming a major triad (root, root+4 semitones, root+7 semitones). Use the preloaded `note-to-hz`. Use eval_hy. Reply with just OK when defined."))
    (print "\n══════════ TURN 2: test it ══════════" :flush True)
    (await (.ask d
      "Use eval_hy to call (chord-hz 60) for middle-C major. Reply with just the returned list."))
    (print "\n══════════ TURN 3: build progression ══════════" :flush True)
    (await (.ask d
      "Save a variable `progression` containing four chord roots for I-IV-V-I in C major (MIDI 60, 65, 67, 60). Then use a list comprehension to compute (chord-hz r) for each root, save as `prog-chords`. Use eval_hy. Reply OK when done."))
    (print "\n══════════ TURN 4: dump state ══════════" :flush True)
    (await (.ask d
      "Call state_dump. Then reply with just a comma-separated list of all the new names you defined (chord-hz, progression, prog-chords)."))
    (print "\n══════════ ARC COMPLETE ══════════" :flush True)
    (finally
      (await (.stop d)))))

(asyncio.run (run))
