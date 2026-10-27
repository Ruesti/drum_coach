# Geführte Übungen — Plan 1 „Klang-Fundament" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ein Ablauf-Spieler, der eine geführte Übung von ~5 Minuten (Einzähler, Crash, Grundgroove, Erklärung per Stimme, Countdown, Variationen, Schluss-Crash) nahtlos abspielt, das Tempo ab dem nächsten Takt ohne Neustart wechselt und eine Positions-Uhr (Abschnitt/Takt/Schlag) liefert — hörbar auf S23 und Linux über eine versteckte Test-Seite.

**Architecture:** Ein reiner Dart-Kern rechnet aus einer `GuidedExercise` einen linearen `RunPlan` (Takte mit Stimmen-Lautstärken + Ereignisse wie Sprach-Clip, Crash, Countdown). Ein Takt-Renderer mischt Takte zu PCM-Stücken (Nachklang wird in den nächsten Takt übertragen, nicht gewickelt). Der `GuidedPlayer` hängt diese Stücke mit ~1 Takt Vorlauf an einen SoLoud-`setBufferStream` an; ein Tempowechsel gilt für den nächsten noch nicht gerenderten Takt. Die Positions-Uhr leitet sich aus der Stream-Position und der Tempo-Historie ab. Englische Sprach-Clips werden offline mit Piper vorgerendert und als Samples mitgemischt — kein zweites Audio-System.

**Tech Stack:** Flutter/Dart, `flutter_soloud` (3.5.x im Lockfile, `setBufferStream`/`addAudioDataStream`), Riverpod, go_router; Python 3 + `piper-tts` (nur Werkzeug, nicht in der App).

**Spec:** `docs/superpowers/specs/2026-10-17-gefuehrte-uebungen-design.md` (freigegeben 18.10.). Dieser Plan deckt §5 Phase 0 + Phase 1 und das Modell aus §3.9 ab; Katalog-Inhalte, Liste/Vorschau/Übungs-Screen, Messung/Auswertung folgen in **Plan 2**, geschrieben nach dem Spike-Ergebnis.

## Global Constraints

- Audio nur über `flutter_soloud` — nie `just_audio`/`audioplayers` (docs/CLAUDE.md).
- BPM-Bereich 40–240; Tempo greift **ab dem nächsten Takt**, nahtlos, Position bleibt (Spec §3.3).
- Kein hörbarer Übergang zwischen Takten; Jitter nicht schlechter als die heutige Schleife; **die bestehende Schleifen-Wiedergabe (`MetronomeEngine`, `buildLoopPlan`, `buildLoopWav`) bleibt unverändert** (Spec §3.4).
- Alle UI-Strings und die Stimme Englisch (Spec §3.2, F3 + Korrektur 18.10.); ein Text je Erklärung (`textEn`) wird angezeigt und vorgelesen; Sprache als Werkzeug-Einstellung.
- App vollständig offline; Clips sind Assets.
- Neue Assets nur frei lizenziert, Eintrag in `assets/audio/CREDITS.md`.
- Nur 4/4 (Spec §2 Nicht-Ziele).
- Desktop-Weiche nur über `lib/app/platform_support.dart`.
- Neuer Code unter `lib/features/guided/`, Tests unter `test/guided/`.

## Review Focus

1. **Tempowechsel kurz vor einer Taktgrenze** (Regler wird während des Vorlaufs bewegt): Erwartung — der Wechsel landet sauber am nächsten noch nicht gerenderten Takt, die Uhr springt nicht zurück, kein Takt doppelt/fehlend. → Test in Task 4 (`tempo change while a bar is queued`).
2. **Sprach-Clip länger als die verfügbare Relax-Zeit bei hohem Tempo** (240 BPM): Erwartung — Relax-Phase wird um ganze Takte verlängert, Clip endet vor dem Countdown-Takt. → Test in Task 3 (`extends relax bars at 240 bpm`).
3. **Nachklang über Taktgrenzen** (Crash ~2 s, Sprach-Clip 3–4 s über mehrere Takte): Erwartung — klingt im Folgetakt weiter, wird nie abgeschnitten oder an den Taktanfang gewickelt. → Test in Task 2 (`carry spans several bars`).
4. **Lehrer aus während der Übung umgeschaltet**: Erwartung — gilt ab dem nächsten gerenderten Takt; ein bereits laufender Clip spielt zu Ende. → Test in Task 4 (`teacher off applies to unrendered bars`).
5. **Pause/Fortsetzen und App im Hintergrund**: Erwartung — Fortsetzen an derselben Stelle; ein eingefrorener Stream (Android-Hintergrund) wird erkannt und der Spieler pausiert statt still weiterzuzählen. → Test in Task 4 (`frozen position pauses the run`).

---

### Task 0: Wegwerf-Spike (Pflicht-Gate, nicht mergen)

Zweck: bestätigt die Architektur, bevor Task 1–7 gebaut werden. Branch `spike/gefuehrt-stream` von diesem Branch, nie gemergt. Keine Tests.

**Files:**
- Create: `tool/stimme/requirements.txt` (`piper-tts`), `tool/stimme/spike_clip.sh`
- Create (Spike-Branch only): `lib/spike/stream_spike_screen.dart`, Route `/debug/stream-spike`

- [ ] **Step 1: Piper einrichten und einen Clip rendern.** venv unter `tool/stimme/.venv` (gitignored), englische Stimme mit kommerziell nutzbarer Lizenz (MODEL_CARD prüfen, Lizenz notieren). Satz: „Next up: add the bass drum on the and of three." → 44,1 kHz mono WAV. Erwartet: Datei < 400 KB, verständlich.
- [ ] **Step 2: Spike-Seite.** `setBufferStream(sampleRate: 44100, channels: mono, format: f32le, bufferingType: preserved, bufferingTimeNeeds: 0.1)`; Takte (Kick/Snare/Hi-Hat aus `backing_sounds.dart`/Snare-PCM, 4/4) einzeln mit `buildLoopWav`-ähnlicher Mischung als Float32 rendern und mit 1 Takt Vorlauf per `addAudioDataStream` anhängen; ab Takt 4 alle 8 Takte den Clip mitmischen; Knöpfe BPM ±10; Anzeige: gerenderter Takt, `getPosition`, berechneter Takt/Schlag; 150 Takte laufen lassen.
- [ ] **Step 3: Messen auf dem NUC-Emulator, dann S23 und Linux-Laptop.** APK auf dem NUC bauen (siehe Memory „Android-Build + Emulator auf dem NUC"), S23 installieren über `cross-machine-test-deploy`; Linux-Bundle auf dem Laptop (docs/CLAUDE.md „Delivery"). Prüfen und notieren in `docs/BERICHT_GEFUEHRT_SPIKE.md`:
  - (a) kein Knacksen/Lücke an Taktgrenzen, auch bei Tempowechsel;
  - (b) `getPosition` läuft monoton über > 64 Takte; Abweichung berechneter Schlag vs. Ohr (Video mit Ton auf dem S23 oder Klick-Aufnahme) < 10 ms;
  - (c) Clip + Schlagzeug gleichzeitig ohne Aussetzer/Ducking;
  - (d) Puffer-Unterlauf? (`onBuffering`-Callback zählen);
  - (e) Speicher nach 150 Takten (preserved hält ~53 MB/5 min — wenn zu viel: `released` + `getStreamTimeConsumed`).
- [ ] **Step 4: Gate mit Uli.** Uli hört am S23 (und Desktop) rein. Entscheidung im Bericht festhalten: **A** Stream-Architektur wie unten (Standard) oder **B** Rückfall (je Abschnitt eine vorgerenderte WAV, Tempowechsel erst am Abschnittsende) bzw. Clips über `flutter_tts`. Bei B: Plan 1 Task 2/4 vor der Ausführung anpassen.
- [ ] **Step 5: Commit** nur `tool/stimme/requirements.txt`, `tool/stimme/spike_clip.sh`, `docs/BERICHT_GEFUEHRT_SPIKE.md` auf `spec-gefuehrte-uebungen` (Spike-Code bleibt auf `spike/gefuehrt-stream`).

```bash
git add tool/stimme/requirements.txt tool/stimme/spike_clip.sh docs/BERICHT_GEFUEHRT_SPIKE.md
git commit -m "spike(gefuehrt): Stream + Piper-Clip auf S23/Linux — Bericht"
```

---

### Task 1: Modell `GuidedExercise` und Clip-Manifest

**Files:**
- Create: `lib/features/guided/models/guided_exercise.dart`
- Create: `lib/features/guided/models/voice_clip.dart`
- Test: `test/guided/guided_exercise_test.dart`

**Interfaces:**
- Produces:
  ```dart
  enum GuidedPackage { kit, pad }
  enum SectionKind { intro, groove, variation, outro }
  class GuidedSection {
    const GuidedSection({required this.kind, required this.line, required this.bars,
      this.textEn, this.speechClipId, this.afterClipId});
    final SectionKind kind; final ExerciseLine line; final int bars;
    final String? textEn;        // explanation: shown (banner/line above notes) AND spoken
    final String? speechClipId;  // clip of textEn, spoken in the groove BEFORE this section
    final String? afterClipId;   // short phrase after the section ("Gut — zurück zum Groove.")
  }
  class GuidedExercise {
    const GuidedExercise({required this.id, required this.name, required this.description,
      required this.package, required this.difficulty, required this.defaultBpm,
      required this.minBpm, required this.maxBpm, required this.gridUnit,
      required this.sections});
    // beatsPerBar fixed 4; validate(): throws ArgumentError on rule violations
    void validate();
    int get variationCount;
    int barsAt(int bpm); // planned bars incl. count-in, without auto extension
  }
  class VoiceClip { const VoiceClip(this.id, this.samples); final String id; final Float32List samples;
    double get durationMs; }
  class ClipManifest { // parsed from assets/voice/manifest.json
    factory ClipManifest.fromJson(Map<String, dynamic> json);
    double durationMs(String id); // throws StateError for unknown id
    Iterable<String> get ids; }
  ```
- Consumes: `ExerciseLine` (`lib/features/lessons/models/...`), `Difficulty`, `NoteGrid`.

- [ ] **Step 1: Failing tests** `guided_exercise_test.dart`:
  - `validate accepts groove/variation alternation`: intro, groove, variation, groove, variation, groove, outro → no throw; `variationCount == 2`.
  - `validate rejects two variations in a row` → `throwsArgumentError` (Ulis Regel: nach jeder Variation Grundgroove).
  - `validate rejects variation without speechClipId or textEn` → throws.
  - `validate rejects non-whole-bar lines` (line ticks not a multiple of one 4/4 bar) → throws.
  - `barsAt counts count-in bar`: sections 0+8+16+8+16+8+1 bars → `barsAt(100) == 58` (1 count-in).
  - `manifest parses durations`: `{"clips":[{"id":"cd_three","ms":420}]}` → `durationMs('cd_three') == 420`; unknown id → `throwsStateError`.
- [ ] **Step 2: Run** `flutter test test/guided/guided_exercise_test.dart` → FAIL (files missing).
- [ ] **Step 3: Implement** both files; immutable, `const` constructors, no Flutter imports in the model.
- [ ] **Step 4: Run** same command → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Modell GuidedExercise + Clip-Manifest`

---

### Task 2: Takt-Renderer mit Nachklang-Übertrag

**Files:**
- Create: `lib/features/guided/bar_renderer.dart`
- Test: `test/guided/bar_renderer_test.dart`

**Interfaces:**
- Consumes: `LoopVoice` (`click_loop_renderer.dart`, unverändert), `softLimit`.
- Produces:
  ```dart
  class SampleHit { const SampleHit({required this.tick, required this.samples, this.gain = 1.0});
    final int tick; final List<double> samples; final double gain; } // clip/crash at a tick of this bar
  class RenderedBar { final Float32List pcm; final int samples; }
  class BarRenderer {
    BarRenderer({this.sampleRate = 44100});
    /// Mixes one bar of [voices] (tickVolumes = one bar) plus [hits] at [bpm]/[factor];
    /// sound past the bar end goes into an internal carry and is added to the next call.
    RenderedBar renderBar({required int bpm, required int factor,
      required List<LoopVoice> voices, List<SampleHit> hits = const []});
    void reset(); // drops the carry (stop/seek)
  }
  ```
  Bar length in samples = `round(sum of tick starts)` computed cumulatively from a running sample counter so bars of mixed tempo never drift (keep a double `_posSec`, each bar spans `round(endSec*sr) - round(startSec*sr)` samples). Limiter `softLimit` applied on output; carry stored unlimited.

- [ ] **Step 1: Failing tests:**
  - `bar length matches tempo`: 120 BPM, factor 4, 16 ticks → `samples == 88200`.
  - `mixed tempo has no drift`: render 3 bars at 120, then 7 at 97 → total samples == `round((3*2.0 + 7*4*60/97) * 44100)` exactly.
  - `carry spans several bars`: hit of 3 s (constant 0.5) at tick 0 of bar 1 at 120 BPM → bar 1 all 0.5, bar 2 first sample 0.5, sample at 1.0 s into bar 2 == 0.0 (|x| < 1e-6).
  - `carry is not wrapped`: bar 1 start (first 100 samples) contains no energy from a hit at its last tick.
  - `reset drops carry`.
  - `identical to buildLoopWav for a single bar`: same voices one bar 100 BPM → int16-quantized pcm equal to `buildLoopWav` body for sounds shorter than the bar.
- [ ] **Step 2: Run** `flutter test test/guided/bar_renderer_test.dart` → FAIL.
- [ ] **Step 3: Implement** `BarRenderer` as above.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Takt-Renderer mit Nachklang-Übertrag`

---

### Task 3: Ablauf-Planer `buildRun`

**Files:**
- Create: `lib/features/guided/run_plan.dart`
- Test: `test/guided/run_plan_test.dart`

**Interfaces:**
- Consumes: `GuidedExercise`, `ClipManifest.durationMs`, `PatternPlayback`/kit voice helpers already used by the practice screen to turn an `ExerciseLine` into per-tick volumes (reuse, do not duplicate: the same functions `SheetPlan`/`buildVoicesPlayback` use).
- Produces:
  ```dart
  enum RunSound { pattern, kick, hihatLoud, hihatSoft, click, crash } // resolved to PCM by the player
  sealed class RunEvent { int get tick; }               // tick within the bar
  class ClipEvent extends RunEvent { final String clipId; }
  class CrashEvent extends RunEvent {}
  class CountdownEvent extends RunEvent { final int remaining; } // 3,2,1,0(=los)
  class RunBar { final int sectionIndex; final int barInSection; final bool isCountIn;
    final bool isCountdown; final Map<RunSound, List<double>> tickVolumes; // one bar
    final List<RunEvent> events; }
  class RunOptions { const RunOptions({this.teacher = true, this.playAlong = true}); final bool teacher, playAlong; }
  /// Plans bars from [fromBar] on at [bpm]; bars before [fromBar] are unchanged
  /// (the player calls this again on tempo/teacher/playAlong changes).
  List<RunBar> buildRun(GuidedExercise ex, {required int bpm, required RunOptions options,
    required ClipManifest clips, int fromBar = 0});
  const countdownClipIds = ['cd_three', 'cd_two', 'cd_one', 'cd_go'];
  const countInClipIds = ['ci_one', 'ci_two', 'ci_three', 'ci_four'];
  ```
  Rules (Spec §3.1–3.4a):
  - Bar 0 = count-in: click on each beat; teacher on → `countInClipIds` on beats 1–4.
  - First groove bar and the outro bar's beat 1 get a `CrashEvent` at tick 0 (pad: same event, the player plays it at gain 0.4 — Spec §3.5).
  - The bar **before** every variation is a countdown bar: `CountdownEvent(3,2,1)` on beats 2–4 and `CountdownEvent(0)` on beat 1 of the variation; teacher on → `countdownClipIds`; click on those beats always (accented ×1.5 when teacher off).
  - Explanation `ClipEvent(speechClipId)` is placed at beat 1 of the latest groove bar such that `start + durationMs + 250 ms ≤ start of countdown bar`; if the groove before is too short, **insert extra groove bars** (whole bars, repeating the groove line) until it fits.
  - `afterClipId` → beat 1 of the first groove bar after the variation (teacher on only).
  - `playAlong == true` → line voices as sounds (pad: `pattern`; kit: kick/hi-hat to `kick`/`hihat*`, rest `pattern`) + no extra click except count-in/countdown; `false` → only `click` on quarters.
  - Countdown clip longer than one beat → half-bar countdown (2 on beat 1, 1 on beat 3, los on the variation's beat 1); clips never overlap.
  - teacher off → no `ClipEvent`s, counts and bar count identical except no auto-extension.
- [ ] **Step 1: Failing tests** (fixture: 1 groove line + 2 variation lines, sections groove 4 / var 8 / groove 4 / var 8 / groove 4 / outro 1; manifest explanation 3200 ms, others 400 ms):
  - `count-in bar first` → `bars[0].isCountIn`, 4 click hits.
  - `crash on first groove bar and outro` → exactly two `CrashEvent`s.
  - `countdown bar precedes each variation` → bars at index of var−1 have `isCountdown` and events remaining 3,2,1 on ticks of beats 2,3,4.
  - `countdown halves when words do not fit a beat`: 240 bpm (beat 250 ms), clips 400 ms → countdown on beat 1 (`cd_two`) and beat 3 (`cd_one`) of the countdown bar, `cd_go` on beat 1 of the variation; no two clips overlap.
  - `explanation ends before countdown at 100 bpm` → clip start ms + 3200 + 250 ≤ countdown bar start ms.
  - `extends relax bars at 240 bpm` → groove-before-variation-2 has more than 4 bars, and the rule above holds.
  - `teacher off has no clips` → zero `ClipEvent`; countdown clicks present with volume 1.5.
  - `playAlong off is click only` → each bar's `tickVolumes` keys == `{click}`.
  - `fromBar keeps earlier bars` → `buildRun(... bpm 100)` vs `buildRun(... bpm 140, fromBar: 10)`: the latter starts at bar 10 and its section indexes continue correctly.
  - `about five minutes` → fixture scaled to real lengths (groove 8, 4 variations × 16, outro 1) at 100 bpm: total duration between 4 and 6 min.
- [ ] **Step 2: Run** `flutter test test/guided/run_plan_test.dart` → FAIL.
- [ ] **Step 3: Implement** `buildRun`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Ablauf-Planer mit Countdown, Erklärung, Auto-Verlängerung`

---

### Task 4: `GuidedPlayer` + Positions-Uhr

**Files:**
- Create: `lib/features/guided/run_clock.dart`
- Create: `lib/features/guided/guided_player.dart`
- Create: `lib/features/guided/pcm_sink.dart` (seam for tests)
- Test: `test/guided/run_clock_test.dart`, `test/guided/guided_player_test.dart`

**Interfaces:**
- Consumes: `buildRun`, `RunBar`, `BarRenderer`, `ClipManifest`, `VoiceClip`, sample PCM (snare from asset as in `MetronomeEngine._prepareAudio`, synthetic kick/hi-hat/click, crash from Task 5 — until Task 5 lands use an empty list).
- Produces:
  ```dart
  abstract class PcmSink { Future<void> open(int sampleRate); void append(Float32List pcm);
    double positionMs(); void pause(bool paused); Future<void> close(); }
  class SoloudPcmSink implements PcmSink { /* setBufferStream f32le mono 44100, preserved, per spike */ }
  class RunPosition { final int bar; final int sectionIndex; final int barInSection;
    final int beat; final int tick; final int bpm; final DateTime plannedAt; }
  class RunClock { void addBar(int index, double startMs, int bpm, int ticks);
    RunPosition? at(double positionMs); } // binary search over rendered bars
  class GuidedPlayer {
    GuidedPlayer({required PcmSink sink, required ClipManifest clips,
      required Future<VoiceClip> Function(String id) loadClip, int lookaheadBars = 1});
    Stream<RunPosition> get positions;   // ~every 10 ms poll, one event per new tick
    Stream<void> get finished;
    Future<void> start(GuidedExercise ex, {required int bpm, required RunOptions options});
    void setBpm(int bpm);                // 40..240 clamp, applies from next unrendered bar
    void setOptions(RunOptions options); // same rule
    void pause(); void resume(); Future<void> stop();
    int get bpm; RunOptions get options;
  }
  ```
  Behaviour: keeps `lookaheadBars` bars rendered ahead of the playing bar; on `setBpm`/`setOptions` re-plans with `buildRun(fromBar: firstUnrenderedBar)`; position frozen for 1 s while not paused → `pause()` + emit last position (Review Focus 5); end of plan → `finished`.
- [ ] **Step 1: Failing tests** with `FakePcmSink` (records appended sample counts, `positionMs` set by test):
  - `run_clock maps ms to bar/beat across tempo change`: bars 0–2 at 120 (2000 ms), bar 3 at 60 (4000 ms) → `at(7000)` == bar 3, beat 2.
  - `appends lookahead on start` → after start, sink received count-in + 1 bar.
  - `tempo change while a bar is queued`: playing bar 5, bar 6 queued, `setBpm(140)` → bar 6 sample count unchanged (old tempo), bar 7 at 140; clock monotone (positions never decrease over a sweep 0..end).
  - `teacher off applies to unrendered bars` → no clip samples mixed after the switch bar; a clip started earlier continues (carry intact).
  - `frozen position pauses the run` → positionMs constant for 1100 ms of polling → `sink.pause(true)` called.
  - `finished fires after outro`.
  - `bpm clamps to 40..240`.
- [ ] **Step 2: Run** `flutter test test/guided/` → FAIL.
- [ ] **Step 3: Implement** `RunClock`, `GuidedPlayer`, `SoloudPcmSink` (all SoLoud calls timeout-guarded like `MetronomeEngine`; guard `_soloudReady` the same way so host tests never touch FFI).
- [ ] **Step 4: Run** → PASS; also `flutter test test/metronome/` unchanged PASS (bestehende Wiedergabe unberührt).
- [ ] **Step 5: Commit** `feat(gefuehrt): Ablauf-Spieler über Buffer-Stream + Positions-Uhr`

---

### Task 5: Crash-Sample

**Files:**
- Create: `assets/audio/crash.mp3` (CC0, z. B. Freesound CC0, ≤ 2,5 s, normalisiert auf Spitze 0.9)
- Modify: `assets/audio/CREDITS.md`
- Create: `lib/features/guided/sample_bank.dart` (loads snare + crash PCM once via `readSamplesFromMem`, exposes synthetic kick/hi-hat/click)
- Test: `test/guided/sample_bank_test.dart`

**Interfaces:**
- Produces: `class SampleBank { static Future<SampleBank> load(); List<double> of(RunSound s); }` — fallback: missing/undecodable crash → synthetic noise burst (`crashFallbackSamples()`, 1,2 s decaying high-passed noise), never silence.
- [ ] **Step 1: Failing tests:** `crash fallback is audible and ≤ 0.9 peak`; `of(RunSound.click) equals MetronomeEngine.pulseSamples()`; asset listed in `CREDITS.md` (file contains `crash.mp3`).
- [ ] **Step 2: Run** `flutter test test/guided/sample_bank_test.dart` → FAIL.
- [ ] **Step 3: Implement**, wire `GuidedPlayer` to `SampleBank`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Crash-Sample + SampleBank`

---

### Task 6: Sprach-Clip-Werkzeug

**Files:**
- Create: `tool/stimme/render_clips.py`, `tool/stimme/saetze.py` (Satzliste: id → englischer Text), `tool/stimme/README.md`
- Create (generated, committed): `assets/voice/*.wav`, `assets/voice/manifest.json`
- Modify: `pubspec.yaml` (`- assets/voice/`), `.gitignore` (`tool/stimme/.venv/`)
- Test: `tool/stimme/test_render_clips.py`, `test/guided/voice_assets_test.dart`

**Interfaces:**
- Produces: `assets/voice/<id>.wav` (44 100 Hz, mono, 16 bit, Stille vorn/hinten auf ≤ 30 ms gekürzt, Spitze −1 dBFS) und `manifest.json` `{"voice":"<piper voice>","lang":"en","clips":[{"id":..,"ms":..,"text":..}]}`; Python-Einstieg `python tool/stimme/render_clips.py [--only id,...] [--voice NAME]`. Feste Sätze in `saetze.py`: `ci_one…ci_four`, `cd_three, cd_two, cd_one, cd_go`, `after_good`, `after_last`, plus die Erklärungen der Demo-Übung aus Task 7. Die Erklärungen der Katalog-Übungen kommen in Plan 2 aus `tool/katalog/gefuehrt.py`.
- Consumes in Dart: `ClipManifest.fromJson`, loader `Future<VoiceClip> loadVoiceClip(String id)` in `lib/features/guided/voice_assets.dart` (decode via SoLoud `readSamplesFromMem`; host tests: WAV parsed in Dart, no FFI).
- [ ] **Step 1: Failing tests:** Python — `trim keeps speech`, `manifest ms equals wav length` (±1 ms), `unchanged text skips re-render` (Hash des Texts + Stimme in manifest). Dart — `every manifest id has an asset`, `countdown clips each ≤ 600 ms` (sonst passt „three" nicht auf einen Schlag bei 100 BPM).
- [ ] **Step 2: Run** `python -m pytest tool/stimme` and `flutter test test/guided/voice_assets_test.dart` → FAIL.
- [ ] **Step 3: Implement**, render, commit Assets.
- [ ] **Step 4: Run** both → PASS.
- [ ] **Step 5: Commit** `feat(gefuehrt): Sprach-Clips (Piper, englisch) + Manifest`

---

### Task 7: Hörprobe-Seite (versteckt) + Abnahme Plan 1

**Files:**
- Create: `lib/features/guided/data/demo_exercise.dart` (eine handgeschriebene Set-Übung: Rock-Achtel-Groove, 3 Variationen — Bassdrum auf 3+, Snare-Ghost auf 2e, offene Hi-Hat auf 4+; je eine Erklärung als Clip + `textEn`; und eine Pad-Mini-Übung: Achtel R L, Variationen Akzent auf 1, Doppelschläge, Paradiddle)
- Create: `lib/features/guided/debug_guided_screen.dart`
- Modify: `lib/app/router.dart` (Route `/debug/guided`, nur erreichbar per Langdruck auf die Versionszeile in Settings — kein sichtbarer Eintrag)
- Test: `test/guided/demo_exercise_test.dart`, `test/guided/debug_guided_screen_test.dart`

**Interfaces:**
- Consumes: `GuidedPlayer`, `RunOptions`, `RunPosition`, `SampleBank`, voice assets.
- Produces: Seite mit Auswahl Set/Pad-Demo, Start/Pause/Stop, BPM ±4 und Tastatur ±/Leertaste (Desktop), Schalter „Teacher" und „Play along", Anzeige `Section 3 of 7 · Variation 1 · bar 5 · beat 2`, Text `textEn` der laufenden/kommenden Variation, Zeitbalken.
- [ ] **Step 1: Failing tests:** `demo exercises validate`; `demo kit ~5 min at default bpm` (4–6 min); widget test — switches toggle `RunOptions` on a fake player, BPM button calls `setBpm(currentBpm + 4)`.
- [ ] **Step 2: Run** `flutter test test/guided/` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` (gesamt) → PASS; `flutter analyze` → no issues.
- [ ] **Step 5: Builds:** APK auf dem NUC (`--build-number` höher als das installierte), Install S23; Linux-Bundle auf dem Laptop. Emulator-Screenshot der Seite nach `~/gefuehrt-plan1-emulator.png`.
- [ ] **Step 6: Abnahme mit Uli** (Spec §4 Punkte 2–4 auf der Hörprobe-Seite): 5 min durchgehört; Tempo mitten drin ±; Lehrer aus; nie ein Wechsel ohne Ansage + Countdown; Stimme klar über dem Groove. Befunde in `docs/BERICHT_GEFUEHRT_PLAN1.md`.
- [ ] **Step 7: Commit** `feat(gefuehrt): Hörprobe-Seite + Demo-Übungen; Bericht Plan 1`

---

## Danach (Plan 2, nach Spike + Abnahme Plan 1)

Katalog-Werkzeug `tool/katalog/gefuehrt.py` + Kurationsseite + Runde 1 (8 Übungen); Liste „Guided" in der Bibliothek mit Set | Pad; Vorschau; Übungs-Screen (Noten, Banner, kommende Variation gedimmt); Kopfhörer-Regel; Pad-Messung + Auswertung je Abschnitt; Log. Plan 3: restliche Inhalte. Dann Set-Messung (Etappe 2 Teil 2) und Hintergrundband (eigene Spec).
