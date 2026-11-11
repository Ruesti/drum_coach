# Engine Teil 1 — Backing-Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Zu jeder Pad-Übung kann eine synthetische Band aus Kick und Hi-Hat mitlaufen — sample-genau im gerenderten Loop, in jedem Tempo, mit eigener Lautstärke, pro Übung gemerkt, im Analyse-Modus nur mit Kopfhörern; nebenbei zählen Vorschlagsnoten nicht mehr als Sollnoten.

**Architecture:** Der bestehende Loop-Renderer (`buildLoopWav`) wird von „Muster + Puls" auf eine Liste von Stimmen (`LoopVoice`) mit weichem Begrenzer umgebaut. Ein reines Modul `loop_voices.dart` baut aus Muster, Puls und Stil die Stimmenliste über einen Zyklus der Länge `lcm(Muster, Takt)`; der Engine ruft nur noch dieses Modul und rendert. Stile und Klänge sind reine Dart-Daten/-Funktionen ohne Flutter, damit ein `dart run`-Werkzeug sie fürs Klang-Gate als WAV rendern kann.

**Tech Stack:** Flutter/Dart (SDK ≥ 3.4), Riverpod (`@riverpod` codegen — keine Regeneration nötig, nur Zustandsfelder und Methoden), flutter_soloud (unverändert), shared_preferences, flutter_test.

**Spec:** `docs/superpowers/specs/2026-09-28-engine-loop-design.md`

## Global Constraints

- Branch `engine-loop`, gestapelt auf `k2-result` (Basis b458324 + Spec d0be7dd). Worktree `/home/uli/projects/drum_coach/.claude/worktrees/k2-result`.
- Tests und Analyzer laufen auf der GPU-Box: `.superpowers/tmp/pctest.sh <pfad>` (rsync + `flutter test`), Analyzer via `ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/flutter analyze'`. Erwartet: nur die 12 bekannten `experimental_member_use`-Warnungen.
- UI-Texte Englisch; Kommentare Englisch; Doku Deutsch.
- `backing_sounds.dart`, `backing_styles.dart`, `stroke_sounds.dart`, `click_loop_renderer.dart`, `loop_voices.dart` importieren **kein** Flutter (nur `dart:math`, `dart:typed_data`), sonst läuft das Klang-Gate-Werkzeug nicht mit `dart run`.
- Tick-Raster: 24 Ticks je Viertel; Stil-Takt = 4/4 = 96 Ticks; Backing nur bei `factor == 24` (Pattern-Uhr), nie im reinen Metronom-Modus.
- Pegel: Hi-Hat ≥ 0,9 → Akzent-Klang; Muster ≥ 1,2 → Akzent-Klang (unverändert); Begrenzer-Knie 0,8.
- Commit-Nachrichten enden mit `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` und `Claude-Session: https://claude.ai/code/session_016aeTD3Yv9A4FgYFJEcFidV`; Nachricht per `-F .superpowers/tmp/<datei>.txt` (Multi-Line `-m` wird vom Worktree-Wächter abgelehnt). Plain git commands only.
- Keine Änderung an Notation, Pulsbalken, Ergebnis-Blatt, Messung (außer §7 Vorschlagsnoten).

## Review Focus

1. Tempo-Änderung bei laufendem Backing: der Zyklus wird neu gerendert, Kick/Hi-Hat bleiben zum Muster ausgerichtet, die globale Tick-Uhr springt auf ein Zyklus-Vielfaches — Test in Task 5 (`buildLoopPlan`: Zyklus ist Vielfaches der Musterlänge) + Gerätetest.
2. Gespeicherte Stil-Kennung, die es nicht mehr gibt (alte Einstellung): erwartet „Off" ohne Fehler — Test in Task 2 (`resolveBackingStyle` mit unbekannter Kennung).
3. Kopfhörer werden mitten in einer Analyse-Sitzung gezogen: erwartet, dass Backing und Klick-Spur stumm werden, bevor das Mikro sie hört — Task 5 meldet den Routenwechsel über `MetronomeState.audioRouteChanges`, Task 7 fragt dann die Kopfhörer neu ab; Test in Task 7 (Routenwechsel mit Mock „none" schaltet ab).
4. Backing-Pegel 0 %: erwartet still, kein Fehler, Stil bleibt gewählt — Test in Task 3 (`gain: 0` ergibt Stille) und Task 7 (Slider auf 0 speichert 0,0).
5. Übung mit 2 Vierteln je Takt und Stil `rock8` (Kick auf Tick 48): erwartet, dass der Kick auf 3 entfällt und der Takt bei 48 Ticks umbricht — Test in Task 2 (`tileBackingHits` mit `beatsPerBar: 2`).

---

## Dateistruktur

- `lib/features/metronome/backing_sounds.dart` — **neu**: `kickSamples`, `hihatSamples` (reine Synthese).
- `lib/features/metronome/backing_styles.dart` — **neu**: `BackingFeel`, `BackingHit`, `BackingStyle`, `backingStyles`, `backingStyleById`, `backingOff`, `resolveBackingStyle`, `tileBackingHits`, `backingBarTicks`.
- `lib/features/metronome/stroke_sounds.dart` — **neu**: `clickSamples`, `rimSamples`, `pulseSamples` (aus dem Engine herausgelöst, reine Funktionen).
- `lib/features/metronome/click_loop_renderer.dart` — **ändern**: `LoopVoice`, `buildLoopWav(voices)`, `softLimit`, `loopCycleTicks`.
- `lib/features/metronome/loop_voices.dart` — **neu**: `LoopPlan`, `buildLoopPlan` (Stimmenliste über den Zyklus).
- `lib/features/metronome/metronome_engine.dart` — **ändern**: `setBacking`, `_startLoop` über `buildLoopPlan`, `synthSamples`/`pulseSamples` delegieren.
- `lib/features/metronome/metronome_provider.dart` — **ändern**: `backingStyleId`, `backingLevel`, `audioRouteChanges`, `setBacking`, `setBackingLevel`, `notifyAudioRouteChanged`.
- `lib/data/local/settings_service.dart` — **ändern**: `backingStyleFor`, `setBackingStyleFor`, `backingLevel`, `setBackingLevel`.
- `lib/features/lessons/models/rudiment.dart` — **ändern**: `backing`.
- `lib/features/lessons/models/pattern_playback.dart` — **ändern**: `isOnsetTick`.
- `lib/features/practice/practice_session_screen.dart` — **ändern**: Beat-Log, `_applyExtras`, Kopfhörer, Optionen-Blatt `BACKING`.
- `tool/render_backing_demo.dart` — **neu**: Klang-Gate-Werkzeug.
- Tests: `test/metronome/backing_sounds_test.dart`, `backing_styles_test.dart`, `loop_voices_test.dart`, `backing_provider_test.dart` (neu); `click_loop_renderer_test.dart` (umgestellt); `test/data/settings_backing_test.dart` (neu); `test/lessons/pattern_playback_test.dart`, `test/features/practice/practice_session_screen_test.dart` (erweitert).
- Doku: `docs/CLAUDE.md`, `docs/BERICHT_ENGINE_LOOP.md`.

---

### Task 1: Backing-Klänge (Kick, Hi-Hat)

**Files:**
- Create: `lib/features/metronome/backing_sounds.dart`
- Test: `test/metronome/backing_sounds_test.dart`

**Interfaces:**
- Produces: `List<double> kickSamples({int sampleRate = 44100})`, `List<double> hihatSamples({required bool accent, int sampleRate = 44100})` — Werte in −1…1, deterministisch.

- [ ] **Step 1: Write the failing tests**

```dart
// test/metronome/backing_sounds_test.dart
import 'package:drum_coach/features/metronome/backing_sounds.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

double _peak(List<double> s) =>
    s.fold(0.0, (m, v) => v.abs() > m ? v.abs() : m);

/// Zero crossings per second — low for a pitched thump, high for noise.
double _zeroCrossingRate(List<double> s) {
  var n = 0;
  for (var i = 1; i < s.length; i++) {
    if ((s[i - 1] < 0) != (s[i] < 0)) n++;
  }
  return n / (s.length / _sr);
}

void main() {
  group('kick', () {
    final kick = kickSamples();
    test('is about 180 ms long and not silent', () {
      expect(kick.length, closeTo(_sr * 0.180, _sr * 0.180 * 0.05));
      expect(_peak(kick), inInclusiveRange(0.3, 0.95));
    });
    test('is a low thump: few zero crossings per second', () {
      expect(_zeroCrossingRate(kick), lessThan(400));
    });
    test('is deterministic', () {
      expect(listEquals(kick, kickSamples()), isTrue);
    });
  });

  group('hi-hat', () {
    final closed = hihatSamples(accent: false);
    final open = hihatSamples(accent: true);
    test('closed is about 60 ms with peak 0.5', () {
      expect(closed.length, closeTo(_sr * 0.060, _sr * 0.060 * 0.05));
      expect(_peak(closed), closeTo(0.5, 1e-9));
    });
    test('accent is longer (about 160 ms) with peak 0.65', () {
      expect(open.length, closeTo(_sr * 0.160, _sr * 0.160 * 0.05));
      expect(open.length, greaterThan(closed.length));
      expect(_peak(open), closeTo(0.65, 1e-9));
    });
    test('is noise: many zero crossings per second', () {
      expect(_zeroCrossingRate(closed), greaterThan(3000));
      expect(_zeroCrossingRate(open), greaterThan(3000));
    });
    test('is deterministic', () {
      expect(listEquals(closed, hihatSamples(accent: false)), isTrue);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/metronome/backing_sounds_test.dart`
Expected: FAIL — `backing_sounds.dart` not found.

- [ ] **Step 3: Implement the sounds**

```dart
// lib/features/metronome/backing_sounds.dart
import 'dart:math' as math;

/// Synthetic backing-loop sounds (Engine part 1). Pure Dart, deterministic —
/// no assets, no licences, identical on every call so tests and renders are
/// stable. Same style as the click/rim synthesis in `stroke_sounds.dart`.

/// Kick: a sine whose pitch glides from 150 Hz down to 48 Hz within the
/// first ~60 ms, decaying over ~180 ms, plus a 2 ms high "beater" click so
/// the thump stays audible on small phone speakers. Peak ≤ 0.9.
List<double> kickSamples({int sampleRate = 44100}) {
  final n = (sampleRate * 0.180).round();
  final out = List<double>.filled(n, 0.0);
  var phase = 0.0;
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final f = 48.0 + 102.0 * math.exp(-t / 0.020); // 150 Hz → 48 Hz
    phase += 2 * math.pi * f / sampleRate;
    final body = math.sin(phase) * math.exp(-12.0 * t);
    final beater =
        math.sin(2 * math.pi * 1800.0 * t) * math.exp(-t / 0.0007) * 0.35;
    out[i] = 0.85 * body + beater;
  }
  return out;
}

/// Hi-hat: white noise through a first-order high-pass (difference filter)
/// with an exponential decay. Closed: ~60 ms, peak 0.5. Accent ("slightly
/// open"): ~160 ms, slower decay, peak 0.65. The peak is normalised exactly.
List<double> hihatSamples({required bool accent, int sampleRate = 44100}) {
  final lengthSec = accent ? 0.160 : 0.060;
  final tau = accent ? 0.035 : 0.012;
  final peak = accent ? 0.65 : 0.5;
  final n = (sampleRate * lengthSec).round();
  final rng = _Lcg(accent ? 11 : 3);
  final out = List<double>.filled(n, 0.0);
  var prev = 0.0;
  var maxAbs = 0.0;
  for (var i = 0; i < n; i++) {
    final white = rng.next() * 2 - 1;
    final highPassed = white - prev;
    prev = white;
    final v = highPassed * math.exp(-(i / sampleRate) / tau);
    out[i] = v;
    if (v.abs() > maxAbs) maxAbs = v.abs();
  }
  if (maxAbs > 0) {
    final scale = peak / maxAbs;
    for (var i = 0; i < n; i++) {
      out[i] *= scale;
    }
  }
  return out;
}

/// Tiny linear congruential generator: deterministic noise without dart:math
/// Random's platform-dependent sequences.
class _Lcg {
  _Lcg(int seed) : _s = seed & 0x7fffffff;
  int _s;
  double next() {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return _s / 0x7fffffff;
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.superpowers/tmp/pctest.sh test/metronome/backing_sounds_test.dart`
Expected: `+7: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/metronome/backing_sounds.dart test/metronome/backing_sounds_test.dart
git commit -F .superpowers/tmp/commit_e1_t1.txt   # "feat(Engine): synthetische Backing-Klänge Kick + Hi-Hat"
```

---

### Task 2: Stil-Vorrat und Kachelung

**Files:**
- Create: `lib/features/metronome/backing_styles.dart`
- Test: `test/metronome/backing_styles_test.dart`

**Interfaces:**
- Produces: `enum BackingFeel { straight, shuffle, swing }`; `class BackingHit { final int tick; final double level; }`; `class BackingStyle { id, label, feel, kick, hihat }`; `const List<BackingStyle> backingStyles`; `BackingStyle? backingStyleById(String? id)`; `const String backingOff = 'off'`; `String? resolveBackingStyle({required String? stored, required String? exerciseDefault})`; `List<double> tileBackingHits(List<BackingHit> hits, {required int beatsPerBar, required int cycleTicks})`; `const int backingBarTicks = 96`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/metronome/backing_styles_test.dart
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('style catalog', () {
    test('has six styles with unique, non-empty ids and labels', () {
      expect(backingStyles.length, 6);
      final ids = backingStyles.map((s) => s.id).toSet();
      expect(ids.length, 6);
      expect(backingStyles.every((s) => s.id.isNotEmpty && s.label.isNotEmpty),
          isTrue);
    });
    test('every hit lies inside one 4/4 bar with a level in (0, 1]', () {
      for (final s in backingStyles) {
        for (final h in [...s.kick, ...s.hihat]) {
          expect(h.tick, inInclusiveRange(0, backingBarTicks - 1),
              reason: '${s.id} tick ${h.tick}');
          expect(h.level, greaterThan(0.0), reason: '${s.id}');
          expect(h.level, lessThanOrEqualTo(1.0), reason: '${s.id}');
        }
      }
    });
    test('the downbeat is always audible on the hi-hat', () {
      for (final s in backingStyles) {
        expect(s.hihat.any((h) => h.tick == 0), isTrue, reason: s.id);
      }
    });
    test('lookup by id; null and unknown give null', () {
      expect(backingStyleById('rock8')!.label, 'Rock 8ths');
      expect(backingStyleById(null), isNull);
      expect(backingStyleById('bossa'), isNull);
      expect(backingStyleById(backingOff), isNull);
    });
  });

  group('resolveBackingStyle', () {
    test('nothing stored → exercise default', () {
      expect(resolveBackingStyle(stored: null, exerciseDefault: 'rock8'),
          'rock8');
      expect(resolveBackingStyle(stored: null, exerciseDefault: null), isNull);
    });
    test('stored choice wins, explicit off stays off', () {
      expect(resolveBackingStyle(stored: 'swing', exerciseDefault: 'rock8'),
          'swing');
      expect(resolveBackingStyle(stored: backingOff, exerciseDefault: 'rock8'),
          isNull);
    });
    test('unknown ids fall back to off, never throw', () {
      expect(resolveBackingStyle(stored: 'bossa', exerciseDefault: 'rock8'),
          isNull);
      expect(resolveBackingStyle(stored: null, exerciseDefault: 'bossa'),
          isNull);
    });
  });

  group('tileBackingHits', () {
    const hits = [BackingHit(0, 1.0), BackingHit(48, 0.8)];
    test('tiles one bar across a two-bar cycle', () {
      final v = tileBackingHits(hits, beatsPerBar: 4, cycleTicks: 192);
      expect(v.length, 192);
      expect(v[0], 1.0);
      expect(v[48], 0.8);
      expect(v[96], 1.0);
      expect(v[144], 0.8);
      expect(v.where((x) => x > 0).length, 4);
    });
    test('a 2/4 bar drops hits beyond the bar and wraps every 48 ticks', () {
      final v = tileBackingHits(hits, beatsPerBar: 2, cycleTicks: 96);
      expect(v[0], 1.0);
      expect(v[48], 1.0); // bar 2 downbeat, not the dropped beat-3 hit
      expect(v.where((x) => x > 0).length, 2);
    });
    test('rock8 hi-hat has eight strokes per bar, quarters louder', () {
      final rock = backingStyleById('rock8')!;
      final v = tileBackingHits(rock.hihat, beatsPerBar: 4, cycleTicks: 96);
      expect(v.where((x) => x > 0).length, 8);
      expect(v[0], greaterThan(v[12]));
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/metronome/backing_styles_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Implement the styles**

```dart
// lib/features/metronome/backing_styles.dart
/// Backing-loop styles (Engine part 1): one 4/4 bar of kick and hi-hat on
/// the 24-ticks-per-quarter grid. Pure data, no Flutter. The player's pad
/// voice is the "snare" — the band deliberately has none.
///
/// Tick cheat sheet (24 per quarter): beat 1 = 0, "e" = 6, "&" = 12,
/// "a" = 18, beat 2 = 24 … beat 4 = 72; third triplet of a beat = +16.

enum BackingFeel { straight, shuffle, swing }

class BackingHit {
  /// 0..95 inside one 4/4 bar.
  final int tick;

  /// 0 < level ≤ 1. Hi-hat hits ≥ 0.9 use the accent ("slightly open") sound.
  final double level;
  const BackingHit(this.tick, this.level);
}

class BackingStyle {
  /// Stable id — stored in settings and exercise data.
  final String id;
  final String label;
  final BackingFeel feel;
  final List<BackingHit> kick;
  final List<BackingHit> hihat;
  const BackingStyle({
    required this.id,
    required this.label,
    required this.feel,
    required this.kick,
    required this.hihat,
  });
}

/// Ticks in one 4/4 bar at 24 ticks per quarter.
const int backingBarTicks = 96;

/// Stored value meaning "the user chose no backing for this exercise" —
/// distinct from "never chose" (null), which falls back to the exercise
/// default.
const String backingOff = 'off';

List<BackingHit> _eighths({double quarter = 1.0, double and = 0.7}) => [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, quarter),
        BackingHit(q * 24 + 12, and),
      ],
    ];

List<BackingHit> _sixteenths(
        {double quarter = 1.0, double and = 0.7, double ea = 0.5}) =>
    [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, quarter),
        BackingHit(q * 24 + 6, ea),
        BackingHit(q * 24 + 12, and),
        BackingHit(q * 24 + 18, ea),
      ],
    ];

final List<BackingStyle> backingStyles = List.unmodifiable([
  BackingStyle(
    id: 'rock8',
    label: 'Rock 8ths',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0)],
    hihat: _eighths(),
  ),
  BackingStyle(
    id: 'rock16',
    label: 'Rock 16ths',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0), BackingHit(60, 0.9)],
    hihat: _sixteenths(),
  ),
  BackingStyle(
    id: 'halftime',
    label: 'Half-time',
    feel: BackingFeel.straight,
    kick: const [BackingHit(0, 1.0), BackingHit(36, 0.9)],
    hihat: [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, q.isEven ? 1.0 : 0.6),
        BackingHit(q * 24 + 12, 0.6),
      ],
    ],
  ),
  BackingStyle(
    id: 'shuffle',
    label: 'Shuffle',
    feel: BackingFeel.shuffle,
    kick: const [BackingHit(0, 1.0), BackingHit(48, 1.0)],
    hihat: [
      for (var q = 0; q < 4; q++) ...[
        BackingHit(q * 24, 1.0),
        BackingHit(q * 24 + 16, 0.6),
      ],
    ],
  ),
  BackingStyle(
    id: 'swing',
    label: 'Swing',
    feel: BackingFeel.swing,
    // Feathered kick on all four, ride-style "spang-a-lang" on the hi-hat.
    kick: const [
      BackingHit(0, 0.4),
      BackingHit(24, 0.4),
      BackingHit(48, 0.4),
      BackingHit(72, 0.4),
    ],
    hihat: const [
      BackingHit(0, 1.0),
      BackingHit(24, 1.0),
      BackingHit(40, 0.6),
      BackingHit(48, 1.0),
      BackingHit(72, 1.0),
      BackingHit(88, 0.6),
    ],
  ),
  BackingStyle(
    id: 'funk16',
    label: 'Funk 16ths',
    feel: BackingFeel.straight,
    kick: const [
      BackingHit(0, 1.0),
      BackingHit(18, 0.9),
      BackingHit(36, 0.9),
      BackingHit(48, 1.0),
      BackingHit(66, 0.9),
    ],
    hihat: _sixteenths(quarter: 1.0, and: 0.8, ea: 0.45),
  ),
]);

BackingStyle? backingStyleById(String? id) {
  if (id == null) return null;
  for (final s in backingStyles) {
    if (s.id == id) return s;
  }
  return null;
}

/// Which style an exercise starts with: the remembered choice (including an
/// explicit off), else the exercise's own default, else off. Unknown ids
/// (a style removed later, a typo in seed data) mean off — never an error.
String? resolveBackingStyle({
  required String? stored,
  required String? exerciseDefault,
}) {
  if (stored == backingOff) return null;
  final id = stored ?? exerciseDefault;
  return backingStyleById(id)?.id;
}

/// Per-tick volumes of one backing voice across [cycleTicks]: the style's
/// bar is tiled every `beatsPerBar × 24` ticks; hits beyond a shorter bar
/// (2/4 exercises) are dropped. Ticks are always 24 per quarter here.
List<double> tileBackingHits(
  List<BackingHit> hits, {
  required int beatsPerBar,
  required int cycleTicks,
}) {
  final bar = beatsPerBar * 24;
  final out = List<double>.filled(cycleTicks, 0.0);
  for (var start = 0; start < cycleTicks; start += bar) {
    for (final h in hits) {
      if (h.tick >= bar) continue;
      final t = start + h.tick;
      if (t < cycleTicks) out[t] = h.level;
    }
  }
  return out;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.superpowers/tmp/pctest.sh test/metronome/backing_styles_test.dart`
Expected: `+10: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/metronome/backing_styles.dart test/metronome/backing_styles_test.dart
git commit -F .superpowers/tmp/commit_e1_t2.txt   # "feat(Engine): Stil-Vorrat Backing (6 Stile), Auflösung und Kachelung"
```

---

### Task 3: Renderer mit Stimmenliste, Begrenzer und Zykluslänge

**Files:**
- Modify: `lib/features/metronome/click_loop_renderer.dart:44-110`
- Modify: `lib/features/metronome/metronome_engine.dart:172-196` (Aufrufstelle)
- Test: `test/metronome/click_loop_renderer_test.dart` (umgestellt + neu)

**Interfaces:**
- Consumes: nichts Neues (Task 1/2 werden erst in Task 5 verdrahtet).
- Produces: `class LoopVoice { tickVolumes, loudSamples, softSamples, loudFrom = 1.0, gain = 1.0 }`; `Uint8List buildLoopWav({required int bpm, required int factor, required List<LoopVoice> voices, int sampleRate = 44100})`; `double softLimit(double x)`; `int loopCycleTicks({required int patternTicks, required int barTicks})`.

- [ ] **Step 1: Rewrite the renderer tests for `LoopVoice` and add the new cases**

Replace the whole file:

```dart
// test/metronome/click_loop_renderer_test.dart
import 'dart:typed_data';

import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _sr = 44100;

Int16List _pcm(Uint8List wav) =>
    wav.buffer.asByteData(44).buffer.asInt16List(44, (wav.length - 44) ~/ 2);

double _rmsAt(Int16List pcm, int startSample, int windowSamples) {
  var sum = 0.0;
  for (var i = startSample;
      i < startSample + windowSamples && i < pcm.length;
      i++) {
    final v = pcm[i] / 32768.0;
    sum += v * v;
  }
  return sum / windowSamples;
}

LoopVoice _click(List<double> vols) => LoopVoice(
      tickVolumes: vols,
      loudSamples: MetronomeEngine.synthSamples(SoundType.click, accent: true),
      softSamples: MetronomeEngine.synthSamples(SoundType.click, accent: false),
      loudFrom: 1.2,
    );

LoopVoice _pulse(int ticks, int every) => LoopVoice(
      tickVolumes: [for (var t = 0; t < ticks; t++) t % every == 0 ? 1.0 : 0.0],
      loudSamples: MetronomeEngine.pulseSamples(),
      softSamples: MetronomeEngine.pulseSamples(),
    );

void main() {
  group('pulse voice (click track next to the exercise)', () {
    const tickSamples = _sr ~/ 4; // 120 BPM, factor 2 → tick = 0.25 s
    final win = _sr ~/ 100;

    test('adds a click on every quarter tick next to a silent pattern', () {
      final wav = buildLoopWav(bpm: 120, factor: 2, voices: [
        _click(const [0.0, 0.0, 0.0, 0.0]),
        _pulse(4, 2),
      ]);
      final pcm = _pcm(wav);
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, 2 * tickSamples, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, tickSamples, win), lessThan(1e-9));
      expect(_rmsAt(pcm, 3 * tickSamples, win), lessThan(1e-9));
    });

    test('without a pulse voice the silent pattern stays silent', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 2, voices: [_click(const [0.0, 0.0, 0.0, 0.0])]);
      final pcm = _pcm(wav);
      for (var t = 0; t < 4; t++) {
        expect(_rmsAt(pcm, t * tickSamples, win), lessThan(1e-9));
      }
    });

    test('the pulse is a shorter, quieter sound than the exercise click', () {
      final pulse = MetronomeEngine.pulseSamples();
      final click =
          MetronomeEngine.synthSamples(SoundType.click, accent: false);
      expect(pulse.length, lessThan(click.length));
      final peak = pulse.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
      expect(peak, lessThan(0.55));
    });
  });

  group('buildLoopWav', () {
    final win = _sr ~/ 100;

    test('loop length is exactly ticks × tick duration', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 1, voices: [_click(const [2.0, 0.7, 0.7, 0.7])]);
      expect(_pcm(wav).length, 2 * _sr);
    });

    test('audible ticks carry energy, silent grid ticks stay silent', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 2, voices: [_click(const [1.0, 0.0, 1.0, 0.0])]);
      final pcm = _pcm(wav);
      const tickSamples = _sr ~/ 4;
      expect(_rmsAt(pcm, 0, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, 2 * tickSamples, win), greaterThan(1e-6));
      expect(_rmsAt(pcm, tickSamples, win), lessThan(1e-9));
      expect(_rmsAt(pcm, 3 * tickSamples, win), lessThan(1e-9));
    });

    test('accent volume produces a louder onset than a normal tick', () {
      final wav = buildLoopWav(
          bpm: 120, factor: 1, voices: [_click(const [2.0, 0.7, 0.7, 0.7])]);
      final pcm = _pcm(wav);
      expect(_rmsAt(pcm, 0, win), greaterThan(2 * _rmsAt(pcm, _sr ~/ 2, win)));
    });

    test('a sound near the loop end wraps into the loop start', () {
      final rim = LoopVoice(
        tickVolumes: const [0.0, 1.0],
        loudSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: true),
        softSamples: MetronomeEngine.synthSamples(SoundType.rim, accent: false),
        loudFrom: 1.2,
      );
      final wav = buildLoopWav(bpm: 240, factor: 4, voices: [rim]);
      expect(_rmsAt(_pcm(wav), 0, win), greaterThan(1e-8),
          reason: 'sound crossing the loop boundary must wrap, not truncate');
    });

    test('voices mix additively and gain scales a voice', () {
      final flat = List.filled(2000, 0.5);
      LoopVoice v(double gain) => LoopVoice(
          tickVolumes: const [1.0], loudSamples: flat, softSamples: flat, gain: gain);
      final one = _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(1.0)]));
      final two = _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(1.0), v(0.5)]));
      final muted = _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(0.0)]));
      expect(two[100] / one[100], closeTo(1.5, 0.02));
      expect(muted.every((s) => s == 0), isTrue);
    });

    test('voices of different cycle lengths are rejected', () {
      expect(
          () => buildLoopWav(bpm: 120, factor: 1, voices: [
                _click(const [1.0, 0.0]),
                _pulse(4, 2),
              ]),
          throwsArgumentError);
      expect(() => buildLoopWav(bpm: 120, factor: 1, voices: const []),
          throwsArgumentError);
    });

    test('soft limiter: quiet signals pass unchanged, loud sums never flat-top',
        () {
      expect(softLimit(0.5), 0.5);
      expect(softLimit(-0.8), -0.8);
      expect(softLimit(1.9), lessThan(1.0));
      expect(softLimit(1.9), greaterThan(0.95));
      expect(softLimit(-3.0), greaterThan(-1.0));
      // Four full-scale voices on the same tick: no two consecutive samples
      // at the ceiling.
      final loud = List.filled(3000, 0.9);
      LoopVoice v() => LoopVoice(
          tickVolumes: const [2.0], loudSamples: loud, softSamples: loud);
      final pcm =
          _pcm(buildLoopWav(bpm: 120, factor: 1, voices: [v(), v(), v(), v()]));
      for (var i = 1; i < 3000; i++) {
        expect(pcm[i - 1] >= 32700 && pcm[i] >= 32700, isFalse,
            reason: 'flat top at $i');
      }
      expect(pcm.every((s) => s >= -32768 && s <= 32767), isTrue);
    });
  });

  group('loopCycleTicks', () {
    test('is the least common multiple of pattern and bar', () {
      expect(loopCycleTicks(patternTicks: 96, barTicks: 96), 96);
      expect(loopCycleTicks(patternTicks: 24, barTicks: 96), 96);
      expect(loopCycleTicks(patternTicks: 144, barTicks: 96), 288);
      expect(loopCycleTicks(patternTicks: 96, barTicks: 48), 96);
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/metronome/click_loop_renderer_test.dart`
Expected: FAIL — `LoopVoice` undefined (compile error).

- [ ] **Step 3: Rewrite `buildLoopWav`** (keep `tickAtPosition` and `advanceGlobalTick` untouched; replace everything from the `buildLoopWav` doc comment to the end of the file)

```dart
/// One voice of the rendered loop: per-tick volumes over the cycle, a loud
/// and a soft sound, the volume from which the loud sound is used, and a
/// track gain. Pattern: loudFrom 1.2 (accent), hi-hat: 0.9, pulse/kick: 1.0.
class LoopVoice {
  const LoopVoice({
    required this.tickVolumes,
    required this.loudSamples,
    required this.softSamples,
    this.loudFrom = 1.0,
    this.gain = 1.0,
  });
  final List<double> tickVolumes;
  final List<double> loudSamples;
  final List<double> softSamples;
  final double loudFrom;
  final double gain;
}

/// Ticks of one rendered cycle when a backing bar of [barTicks] runs next to
/// a pattern of [patternTicks]: the least common multiple, so both repeat
/// whole. Without backing the cycle is just the pattern.
int loopCycleTicks({required int patternTicks, required int barTicks}) {
  int gcd(int a, int b) => b == 0 ? a : gcd(b, a % b);
  return patternTicks ~/ gcd(patternTicks, barTicks) * barTicks;
}

double _tanh(double x) {
  final e = math.exp(2 * x);
  return (e - 1) / (e + 1);
}

/// Soft limiter: linear up to ±0.8, then a tanh knee that never reaches
/// ±1.0 — four voices on one tick stay loud without the crackle of hard
/// clipping. A single voice below 0.8 is bit-identical to the old output.
double softLimit(double x) {
  const knee = 0.8;
  final a = x.abs();
  if (a <= knee) return x;
  final y = knee + (1 - knee) * _tanh((a - knee) / (1 - knee));
  return x < 0 ? -y : y;
}

/// Renders one loop cycle from [voices] as a mono 16-bit WAV that loops
/// sample-exactly. All voices span the same cycle (same `tickVolumes`
/// length); each hit is `sound × tickVolume × gain`, summed, then soft
/// limited. Sounds crossing the loop boundary wrap into the start.
Uint8List buildLoopWav({
  required int bpm,
  required int factor,
  required List<LoopVoice> voices,
  int sampleRate = 44100,
}) {
  if (voices.isEmpty) throw ArgumentError('buildLoopWav needs a voice');
  final ticks = voices.first.tickVolumes.length;
  for (final v in voices) {
    if (v.tickVolumes.length != ticks) {
      throw ArgumentError('all voices must span the same cycle: '
          '${v.tickVolumes.length} vs $ticks ticks');
    }
  }
  final tickDurSec = 60.0 / bpm / factor;
  final totalSamples = (ticks * tickDurSec * sampleRate).round();
  final mix = Float64List(totalSamples);

  for (final v in voices) {
    if (v.gain <= 0) continue;
    for (var t = 0; t < ticks; t++) {
      final vol = v.tickVolumes[t];
      if (vol <= 0) continue;
      final src = vol >= v.loudFrom ? v.loudSamples : v.softSamples;
      final start = (t * tickDurSec * sampleRate).round();
      final scale = vol * v.gain;
      for (var i = 0; i < src.length; i++) {
        mix[(start + i) % totalSamples] += src[i] * scale;
      }
    }
  }

  final dataSize = totalSamples * 2;
  final bd = ByteData(44 + dataSize);
  void str(int off, String s) {
    for (var i = 0; i < s.length; i++) {
      bd.setUint8(off + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bd.setUint32(4, 36 + dataSize, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little);
  bd.setUint16(22, 1, Endian.little);
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bd.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < totalSamples; i++) {
    final s16 = (softLimit(mix[i]) * 32767).round();
    bd.setInt16(44 + i * 2, s16, Endian.little);
  }
  return bd.buffer.asUint8List();
}
```

Add `import 'dart:math' as math;` at the top of the file (next to `dart:typed_data`).

- [ ] **Step 4: Update the engine call site** (`metronome_engine.dart` `_startLoop`, the `final wav = buildLoopWav(...)` block) so the app compiles — Task 5 replaces this again with `buildLoopPlan`:

```dart
    final volumes0 = _loopVolumes();
    final wav = buildLoopWav(
      bpm: _bpm,
      factor: _factor,
      voices: [
        LoopVoice(
          tickVolumes: volumes0,
          loudSamples: synthetic
              ? synthSamples(fallbackSound, accent: true)
              : _snarePcm,
          softSamples: synthetic
              ? synthSamples(fallbackSound, accent: false)
              : _snarePcm,
          loudFrom: 1.2,
        ),
        if (_pulse && _beatVolumes != null && _beatVolumes!.isNotEmpty)
          LoopVoice(
            tickVolumes: [
              for (var t = 0; t < volumes0.length; t++)
                t % _factor == 0 ? 1.0 : 0.0
            ],
            loudSamples: pulseSamples(),
            softSamples: pulseSamples(),
          ),
      ],
    );
```

- [ ] **Step 5: Run the renderer tests and the whole metronome folder**

Run: `.superpowers/tmp/pctest.sh test/metronome/`
Expected: all passed (renderer 12, plus the existing loop_position/click_track/… tests).

- [ ] **Step 6: Commit**

```bash
git add lib/features/metronome/click_loop_renderer.dart lib/features/metronome/metronome_engine.dart test/metronome/click_loop_renderer_test.dart
git commit -F .superpowers/tmp/commit_e1_t3.txt   # "feat(Engine): Loop-Renderer mit Stimmenliste, weichem Begrenzer und lcm-Zyklus"
```

---

### Task 4: Reine Anschlag-Klänge + Stimmenplan (`loop_voices.dart`)

**Files:**
- Create: `lib/features/metronome/stroke_sounds.dart`
- Create: `lib/features/metronome/loop_voices.dart`
- Modify: `lib/features/metronome/metronome_engine.dart:560-616` (`synthSamples`, `pulseSamples`, `_rimSample` → delegieren)
- Test: `test/metronome/loop_voices_test.dart`

**Interfaces:**
- Consumes: `kickSamples`, `hihatSamples` (Task 1); `BackingStyle`, `tileBackingHits` (Task 2); `LoopVoice`, `loopCycleTicks` (Task 3).
- Produces: `clickSamples({required bool accent, int sampleRate = 44100})`, `rimSamples({required bool accent, int sampleRate = 44100})`, `pulseSamples({int sampleRate = 44100})` (stroke_sounds.dart); `class LoopPlan { final int cycleTicks; final List<double> patternVolumes; final List<LoopVoice> voices; }`; `LoopPlan buildLoopPlan({required List<double> patternVolumes, required List<double> patternLoud, required List<double> patternSoft, required int factor, bool pulse = false, List<double>? pulseSound, BackingStyle? backing, double backingLevel = 0.7, int beatsPerBar = 4, List<double>? kickSound, List<double>? hihatLoud, List<double>? hihatSoft})`; `const int maxBackingCycleBars = 64`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/metronome/loop_voices_test.dart
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/metronome/stroke_sounds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final loud = clickSamples(accent: true);
  final soft = clickSamples(accent: false);
  final kick = List.filled(100, 0.5);
  final hh = List.filled(50, 0.4);
  // 4 sixteenths = one quarter = 24 ticks, accent on the first.
  final quarter = [for (var t = 0; t < 24; t++) t % 6 == 0 ? (t == 0 ? 2.0 : 0.85) : 0.0];

  LoopPlan plan({BackingStyle? backing, bool pulse = false, int beatsPerBar = 4,
          int factor = 24, List<double>? pattern}) =>
      buildLoopPlan(
        patternVolumes: pattern ?? quarter,
        patternLoud: loud,
        patternSoft: soft,
        factor: factor,
        pulse: pulse,
        pulseSound: pulseSamples(),
        backing: backing,
        backingLevel: 0.7,
        beatsPerBar: beatsPerBar,
        kickSound: kick,
        hihatLoud: hh,
        hihatSoft: hh,
      );

  test('without backing the cycle is the pattern itself, one voice', () {
    final p = plan();
    expect(p.cycleTicks, 24);
    expect(p.voices.length, 1);
    expect(p.patternVolumes, quarter);
  });

  test('pulse adds a voice with 1.0 on every quarter tick', () {
    final p = plan(pulse: true, pattern: List.filled(48, 0.85));
    expect(p.voices.length, 2);
    final pulseVols = p.voices[1].tickVolumes;
    expect(pulseVols[0], 1.0);
    expect(pulseVols[24], 1.0);
    expect(pulseVols[1], 0.0);
    expect(pulseVols.where((v) => v > 0).length, 2);
  });

  test('backing stretches the cycle to whole bars and tiles the pattern', () {
    final p = plan(backing: backingStyleById('rock8'));
    expect(p.cycleTicks, 96);
    expect(p.patternVolumes.length, 96);
    expect(p.patternVolumes[24], 2.0); // pattern repeats every 24 ticks
    expect(p.patternVolumes[30], 0.85);
    expect(p.voices.length, 3);
    final kickVoice = p.voices[1];
    final hhVoice = p.voices[2];
    expect(kickVoice.gain, 0.7);
    expect(kickVoice.tickVolumes[0], 1.0);
    expect(kickVoice.tickVolumes[48], 1.0);
    expect(hhVoice.loudFrom, 0.9);
    expect(hhVoice.tickVolumes.where((v) => v > 0).length, 8);
    expect(p.voices.every((v) => v.tickVolumes.length == 96), isTrue);
  });

  test('a 2/4 exercise gets a 48-tick bar', () {
    final p = plan(backing: backingStyleById('rock8'), beatsPerBar: 2);
    expect(p.cycleTicks, 48);
    expect(p.voices[1].tickVolumes.where((v) => v > 0).length, 1);
  });

  test('backing is ignored outside the 24-tick pattern clock', () {
    final p = plan(backing: backingStyleById('rock8'), factor: 2,
        pattern: const [2.0, 0.7]);
    expect(p.cycleTicks, 2);
    expect(p.voices.length, 1);
  });

  test('an absurdly long cycle drops the backing instead of rendering minutes',
      () {
    // 97 ticks vs a 96-tick bar → lcm = 97 bars > 64.
    final p = plan(backing: backingStyleById('rock8'),
        pattern: List.filled(97, 0.85));
    expect(p.cycleTicks, 97);
    expect(p.voices.length, 1);
  });

  test('stroke sounds match the engine ones (pure copies)', () {
    expect(clickSamples(accent: true).length, (44100 * 0.030).round());
    expect(rimSamples(accent: false).length, (44100 * 0.10).round());
    expect(pulseSamples().length, (44100 * 0.012).round());
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/metronome/loop_voices_test.dart`
Expected: FAIL — files not found.

- [ ] **Step 3: Extract the pure stroke sounds**

```dart
// lib/features/metronome/stroke_sounds.dart
import 'dart:math' as math;

/// The exercise sounds as pure functions (no Flutter, no SoLoud) — shared by
/// the engine, the loop renderer tests and the backing-demo tool.

/// Click: 30 ms decaying sine, 1200 Hz accent / 800 Hz normal.
List<double> clickSamples({required bool accent, int sampleRate = 44100}) {
  final amplitude = accent ? 0.95 : 0.55;
  final frequency = accent ? 1200.0 : 800.0;
  final n = (sampleRate * 0.030).round();
  return [
    for (var i = 0; i < n; i++)
      amplitude *
          math.exp(-140.0 * (i / sampleRate)) *
          math.sin(2 * math.pi * frequency * (i / sampleRate)),
  ];
}

/// Rim: 100 ms, three damped partials (shell, rim, snap).
List<double> rimSamples({required bool accent, int sampleRate = 44100}) {
  final amplitude = accent ? 0.95 : 0.55;
  final n = (sampleRate * 0.10).round();
  return [for (var i = 0; i < n; i++) _rimSample(i / sampleRate, amplitude)];
}

/// The click track's own voice: a short, high, dry tick — clearly apart
/// from the exercise sounds so the ear can tell the pulse from the pattern.
List<double> pulseSamples({int sampleRate = 44100}) {
  final n = (sampleRate * 0.012).round();
  return [
    for (var i = 0; i < n; i++)
      0.45 *
          math.exp(-350.0 * (i / sampleRate)) *
          math.sin(2 * math.pi * 2600.0 * (i / sampleRate)),
  ];
}

double _rimSample(double t, double amplitude) {
  final shell = math.sin(2 * math.pi * 280 * t) * math.exp(-55.0 * t) * 0.45;
  final rim = math.sin(2 * math.pi * 680 * t) * math.exp(-130.0 * t) * 0.60;
  final snap = math.sin(2 * math.pi * 2100 * t) * math.exp(-600.0 * t) * 0.35;
  return amplitude * (shell + rim + snap);
}
```

In `metronome_engine.dart`: add `import 'stroke_sounds.dart' as sounds;`, then replace the bodies of `synthSamples` and `pulseSamples` and delete `_rimSample`:

```dart
  static List<double> synthSamples(
    SoundType type, {
    required bool accent,
    int sampleRate = 44100,
  }) {
    switch (type) {
      case SoundType.click:
        return sounds.clickSamples(accent: accent, sampleRate: sampleRate);
      case SoundType.rim:
        return sounds.rimSamples(accent: accent, sampleRate: sampleRate);
      case SoundType.snare:
        throw ArgumentError('snare is sample-based; use the decoded PCM');
    }
  }

  static List<double> pulseSamples({int sampleRate = 44100}) =>
      sounds.pulseSamples(sampleRate: sampleRate);
```

Keep `calibrationClickWav`/`_buildClickWav` as they are.

- [ ] **Step 4: Implement the loop plan**

```dart
// lib/features/metronome/loop_voices.dart
import 'backing_styles.dart';
import 'click_loop_renderer.dart';

/// Backing is dropped when the cycle would exceed this many 4/4 bars — a
/// pattern that odd does not exist in the catalog, and rendering minutes of
/// WAV on every tempo change would stall the loop rebuild.
const int maxBackingCycleBars = 64;

/// What the engine renders: the cycle length, the pattern volumes tiled to
/// that cycle (the tick clock and beat poller read these) and every voice.
class LoopPlan {
  const LoopPlan({
    required this.cycleTicks,
    required this.patternVolumes,
    required this.voices,
  });
  final int cycleTicks;
  final List<double> patternVolumes;
  final List<LoopVoice> voices;
}

/// Builds the voice list for one loop cycle. Pure: the engine passes its
/// state in, the demo tool passes constants.
///
/// - [patternVolumes]: one pattern cycle (or the plain-metronome quarter).
/// - [pulse]: the click track — 1.0 on every [factor]-th tick.
/// - [backing]: kick + hi-hat from a style, tiled per bar, only on the
///   24-tick pattern clock (`factor == 24`); the cycle then grows to
///   `lcm(pattern, bar)` and the pattern repeats to fill it.
LoopPlan buildLoopPlan({
  required List<double> patternVolumes,
  required List<double> patternLoud,
  required List<double> patternSoft,
  required int factor,
  bool pulse = false,
  List<double>? pulseSound,
  BackingStyle? backing,
  double backingLevel = 0.7,
  int beatsPerBar = 4,
  List<double>? kickSound,
  List<double>? hihatLoud,
  List<double>? hihatSoft,
}) {
  final patternTicks = patternVolumes.length;
  var cycle = patternTicks;
  var useBacking = backing != null &&
      factor == 24 &&
      kickSound != null &&
      hihatLoud != null &&
      hihatSoft != null;
  if (useBacking) {
    cycle = loopCycleTicks(
        patternTicks: patternTicks, barTicks: beatsPerBar * factor);
    if (cycle > maxBackingCycleBars * backingBarTicks) {
      useBacking = false;
      cycle = patternTicks;
    }
  }
  final tiled = [for (var t = 0; t < cycle; t++) patternVolumes[t % patternTicks]];
  final voices = <LoopVoice>[
    LoopVoice(
      tickVolumes: tiled,
      loudSamples: patternLoud,
      softSamples: patternSoft,
      loudFrom: 1.2,
    ),
  ];
  if (pulse && pulseSound != null) {
    voices.add(LoopVoice(
      tickVolumes: [for (var t = 0; t < cycle; t++) t % factor == 0 ? 1.0 : 0.0],
      loudSamples: pulseSound,
      softSamples: pulseSound,
    ));
  }
  if (useBacking) {
    voices.add(LoopVoice(
      tickVolumes:
          tileBackingHits(backing.kick, beatsPerBar: beatsPerBar, cycleTicks: cycle),
      loudSamples: kickSound,
      softSamples: kickSound,
      gain: backingLevel,
    ));
    voices.add(LoopVoice(
      tickVolumes:
          tileBackingHits(backing.hihat, beatsPerBar: beatsPerBar, cycleTicks: cycle),
      loudSamples: hihatLoud,
      softSamples: hihatSoft,
      loudFrom: 0.9,
      gain: backingLevel,
    ));
  }
  return LoopPlan(cycleTicks: cycle, patternVolumes: tiled, voices: voices);
}
```

- [ ] **Step 5: Run the tests**

Run: `.superpowers/tmp/pctest.sh test/metronome/`
Expected: all passed (loop_voices 7 new).

- [ ] **Step 6: Commit**

```bash
git add lib/features/metronome/stroke_sounds.dart lib/features/metronome/loop_voices.dart lib/features/metronome/metronome_engine.dart test/metronome/loop_voices_test.dart
git commit -F .superpowers/tmp/commit_e1_t4.txt   # "feat(Engine): Stimmenplan buildLoopPlan + reine Anschlag-Klänge"
```

---

### Task 5: Klang-Gate — Demo-Werkzeug, Rendern, Urteil des Auftraggebers

**Files:**
- Create: `tool/render_backing_demo.dart`

**Interfaces:**
- Consumes: `buildLoopPlan` (Task 4), `buildLoopWav` (Task 3), `backingStyles` (Task 2), `kickSamples`/`hihatSamples` (Task 1), `clickSamples`/`pulseSamples` (Task 4).

- [ ] **Step 1: Write the tool**

```dart
// tool/render_backing_demo.dart
// Renders every backing style as a WAV for the sound gate (spec §9):
//   dart run tool/render_backing_demo.dart <out-dir> [bpm] [bars]
// Each style twice: with an eighth-note R L click pattern and solo.
import 'dart:io';
import 'dart:typed_data';

import 'package:drum_coach/features/metronome/backing_sounds.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:drum_coach/features/metronome/click_loop_renderer.dart';
import 'package:drum_coach/features/metronome/loop_voices.dart';
import 'package:drum_coach/features/metronome/stroke_sounds.dart';

void main(List<String> args) {
  final outDir = Directory(args.isNotEmpty ? args[0] : 'backing-demo')
    ..createSync(recursive: true);
  final bpm = args.length > 1 ? int.parse(args[1]) : 90;
  final bars = args.length > 2 ? int.parse(args[2]) : 8;
  const factor = 24;
  // One 4/4 bar of eighths, accent on the downbeat.
  final eighths = [
    for (var t = 0; t < 96; t++)
      t % 12 == 0 ? (t == 0 ? 2.0 : 0.85) : 0.0
  ];
  final silent = List<double>.filled(96, 0.0);
  final kick = kickSamples();
  final hhLoud = hihatSamples(accent: true);
  final hhSoft = hihatSamples(accent: false);
  for (final style in backingStyles) {
    for (final withPattern in [true, false]) {
      final plan = buildLoopPlan(
        patternVolumes: withPattern ? eighths : silent,
        patternLoud: clickSamples(accent: true),
        patternSoft: clickSamples(accent: false),
        factor: factor,
        backing: style,
        backingLevel: 0.7,
        beatsPerBar: 4,
        kickSound: kick,
        hihatLoud: hhLoud,
        hihatSoft: hhSoft,
      );
      final oneBar = buildLoopWav(bpm: bpm, factor: factor, voices: plan.voices);
      final name = '${style.id}${withPattern ? '' : '_solo'}.wav';
      File('${outDir.path}/$name').writeAsBytesSync(_repeat(oneBar, bars));
      stdout.writeln('wrote $name');
    }
  }
}

/// Repeats the data chunk of a 16-bit mono WAV [times] and fixes the header
/// sizes. The renderer wraps sound tails into the loop start, so the joins
/// are seamless.
Uint8List _repeat(Uint8List wav, int times) {
  final data = wav.sublist(44);
  final out = ByteData(44 + data.length * times);
  final bytes = out.buffer.asUint8List();
  bytes.setRange(0, 44, wav);
  for (var i = 0; i < times; i++) {
    bytes.setRange(44 + i * data.length, 44 + (i + 1) * data.length, data);
  }
  out.setUint32(4, 36 + data.length * times, Endian.little);
  out.setUint32(40, data.length * times, Endian.little);
  return bytes;
}
```

- [ ] **Step 2: Render on the GPU box and copy the files home**

Run (after `pctest.sh` synced the checkout):
```bash
ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/dart run tool/render_backing_demo.dart ~/backing-demo 90 8'
mkdir -p ~/backing-demo && scp 'pc:~/backing-demo/*.wav' ~/backing-demo/
ls -la ~/backing-demo
```
Expected: 12 files (`rock8.wav`, `rock8_solo.wav`, …), each about 1.9 MB (8 bars at 90 BPM ≈ 21 s).

- [ ] **Step 3: Sanity-check the renders without ears**

```bash
python3 - <<'EOF'
import wave, struct, glob
for p in sorted(glob.glob('/home/uli/backing-demo/*.wav')):
    w = wave.open(p); n = w.getnframes(); fr = w.getframerate()
    data = w.readframes(n); w.close()
    vals = struct.unpack('<%dh' % n, data)
    peak = max(abs(v) for v in vals) / 32768
    print(f'{p.split("/")[-1]:18s} {n/fr:5.1f} s peak {peak:.2f}')
EOF
```
Expected: every file ≈ 21.3 s, peak between 0.6 and 0.99, no file silent.

- [ ] **Step 4: Sound gate with the client** — present the folder (`ls ~/backing-demo`, plus how to play: copy to the laptop or phone), ask for the verdict: sounds like a band, kick/hi-hat balance, styles distinguishable. If changes are requested, edit only `backing_sounds.dart` / `backing_styles.dart`, re-run Task 1/2 tests, re-render, ask again. **Do not start Task 6 before the "Ja".**

- [ ] **Step 5: Commit**

```bash
git add tool/render_backing_demo.dart
git commit -F .superpowers/tmp/commit_e1_t5.txt   # "tool(Engine): Klang-Gate-Werkzeug rendert die Backing-Stile als WAV"
```

---

### Task 6: Engine und Provider verdrahten

**Files:**
- Modify: `lib/features/metronome/metronome_engine.dart` (`_startLoop` 172-256, Setter 504-540)
- Modify: `lib/features/metronome/metronome_provider.dart` (State 13-63, Notifier 65-171)
- Test: `test/metronome/backing_provider_test.dart`

**Interfaces:**
- Consumes: `buildLoopPlan` (Task 4), `backingStyleById` (Task 2), `kickSamples`/`hihatSamples` (Task 1).
- Produces: Engine `void setBacking(BackingStyle? style, {required double level, required int beatsPerBar})`; Provider `MetronomeState.backingStyleId` (String?), `MetronomeState.backingLevel` (double, 0.7), `MetronomeState.audioRouteChanges` (int, 0); `void setBacking(String? styleId, {required int beatsPerBar})`, `void setBackingLevel(double level)`, `@visibleForTesting void notifyAudioRouteChanged()`.

- [ ] **Step 1: Write the failing provider tests**

```dart
// test/metronome/backing_provider_test.dart
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// No engine (no SoLoud) — the setters are engine-null-safe.
class _IdleMetronomeNotifier extends MetronomeNotifier {
  @override
  MetronomeState build() => const MetronomeState();
}

void main() {
  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(overrides: [
      metronomeNotifierProvider.overrideWith(() => _IdleMetronomeNotifier()),
    ]);
    addTearDown(container.dispose);
  });

  test('backing is off with level 0.7 until a screen chooses a style', () {
    final s = container.read(metronomeNotifierProvider);
    expect(s.backingStyleId, isNull);
    expect(s.backingLevel, 0.7);
  });

  test('setBacking stores the style id, unknown ids become off', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    n.setBacking('rock8', beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    n.setBacking('bossa', beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    n.setBacking(null, beatsPerBar: 4);
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
  });

  test('setBackingLevel clamps to 0..1', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    n.setBackingLevel(0.3);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.3);
    n.setBackingLevel(1.7);
    expect(container.read(metronomeNotifierProvider).backingLevel, 1.0);
    n.setBackingLevel(-1);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.0);
  });

  test('an audio route change bumps a counter screens can listen to', () {
    final n = container.read(metronomeNotifierProvider.notifier);
    expect(container.read(metronomeNotifierProvider).audioRouteChanges, 0);
    n.notifyAudioRouteChanged();
    n.notifyAudioRouteChanged();
    expect(container.read(metronomeNotifierProvider).audioRouteChanges, 2);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/metronome/backing_provider_test.dart`
Expected: FAIL — `backingStyleId` undefined.

- [ ] **Step 3: Engine — fields, setter, `_startLoop` via `buildLoopPlan`**

Imports in `metronome_engine.dart`: add `import 'backing_sounds.dart';`, `import 'backing_styles.dart';`, `import 'loop_voices.dart';`.

Fields (next to `bool _pulse = false;`):

```dart
  /// Backing loop (Engine part 1): kick + hi-hat from a style, only on the
  /// 24-tick pattern clock. Sounds are synthesised once per process.
  BackingStyle? _backing;
  double _backingLevel = 0.7;
  int _beatsPerBar = 4;
  static final List<double> _kickPcm = kickSamples();
  static final List<double> _hihatLoudPcm = hihatSamples(accent: true);
  static final List<double> _hihatSoftPcm = hihatSamples(accent: false);

  void setBacking(BackingStyle? style,
      {required double level, required int beatsPerBar}) {
    if (_backing == style &&
        _backingLevel == level &&
        _beatsPerBar == beatsPerBar) {
      return;
    }
    _backing = style;
    _backingLevel = level;
    _beatsPerBar = beatsPerBar;
    _scheduleLoopRebuild();
  }
```

In `_startLoop`, replace the Task-3 `buildLoopWav(...)` block and the later `final volumes = List<double>.of(_loopVolumes());` with:

```dart
    LoopPlan plan;
    try {
      plan = buildLoopPlan(
        patternVolumes: _loopVolumes(),
        patternLoud: synthetic
            ? synthSamples(fallbackSound, accent: true)
            : _snarePcm,
        patternSoft: synthetic
            ? synthSamples(fallbackSound, accent: false)
            : _snarePcm,
        factor: _factor,
        pulse: _pulse && _beatVolumes != null && _beatVolumes!.isNotEmpty,
        pulseSound: pulseSamples(),
        backing: _beatVolumes != null && _beatVolumes!.isNotEmpty
            ? _backing
            : null,
        backingLevel: _backingLevel,
        beatsPerBar: _beatsPerBar,
        kickSound: _kickPcm,
        hihatLoud: _hihatLoudPcm,
        hihatSoft: _hihatSoftPcm,
      );
    } catch (e) {
      // A broken backing must never silence the exercise: render without it.
      debugPrint('backing plan failed, rendering without backing: $e');
      plan = buildLoopPlan(
        patternVolumes: _loopVolumes(),
        patternLoud: synthetic
            ? synthSamples(fallbackSound, accent: true)
            : _snarePcm,
        patternSoft: synthetic
            ? synthSamples(fallbackSound, accent: false)
            : _snarePcm,
        factor: _factor,
        pulse: _pulse && _beatVolumes != null && _beatVolumes!.isNotEmpty,
        pulseSound: pulseSamples(),
      );
    }
    final wav = buildLoopWav(bpm: _bpm, factor: _factor, voices: plan.voices);
```
and further down
```dart
    final volumes = List<double>.of(plan.patternVolumes);
```
(the rest of `_startLoop` — `realLoopMs`, `_loopTickDurMs`, `_loopVolumesActive`, `_lastGlobalTick` — stays as it is and now works on the cycle length.)

- [ ] **Step 4: Provider — state fields and setters**

`MetronomeState`: add fields, constructor defaults and `copyWith` entries:

```dart
  /// Backing loop (Engine part 1): chosen style id (null = off) and the
  /// backing track's own level 0..1.
  final String? backingStyleId;
  final double backingLevel;

  /// Bumped on every headphone plug/unplug so the practice screen can
  /// re-check headphones (the analysis-mode rule) without owning the single
  /// platform callback this notifier already holds.
  final int audioRouteChanges;
```
constructor: `this.backingStyleId, this.backingLevel = 0.7, this.audioRouteChanges = 0,`; `copyWith` needs an explicit "set to null" path for the style:

```dart
  MetronomeState copyWith({
    bool? isPlaying,
    int? bpm,
    Subdivision? subdivision,
    SoundType? soundType,
    int? currentBeatIndex,
    bool? isAccent,
    DateTime? lastBeatPlannedAt,
    bool? clickTrack,
    String? backingStyleId,
    bool clearBackingStyle = false,
    double? backingLevel,
    int? audioRouteChanges,
  }) {
    return MetronomeState(
      // … existing fields …
      backingStyleId:
          clearBackingStyle ? null : (backingStyleId ?? this.backingStyleId),
      backingLevel: backingLevel ?? this.backingLevel,
      audioRouteChanges: audioRouteChanges ?? this.audioRouteChanges,
    );
  }
```

Notifier (`import 'backing_styles.dart';`): in `build()` replace the route callback:

```dart
    AudioCapabilities.onDevicesChanged(notifyAudioRouteChanged);
```
and add:

```dart
  int _beatsPerBar = 4;

  /// Headphone plug/unplug: reroute the engine and tell listening screens.
  @visibleForTesting
  void notifyAudioRouteChanged() {
    _engine?.handleAudioRouteChanged();
    if (_disposed) return;
    state = state.copyWith(audioRouteChanges: state.audioRouteChanges + 1);
  }

  /// Backing loop next to a pattern. Unknown ids mean off.
  void setBacking(String? styleId, {required int beatsPerBar}) {
    final style = backingStyleById(styleId);
    _beatsPerBar = beatsPerBar;
    _engine?.setBacking(style, level: state.backingLevel, beatsPerBar: beatsPerBar);
    state = style == null
        ? state.copyWith(clearBackingStyle: true)
        : state.copyWith(backingStyleId: style.id);
  }

  void setBackingLevel(double level) {
    final clamped = level.clamp(0.0, 1.0).toDouble();
    _engine?.setBacking(backingStyleById(state.backingStyleId),
        level: clamped, beatsPerBar: _beatsPerBar);
    state = state.copyWith(backingLevel: clamped);
  }
```

- [ ] **Step 5: Run the metronome tests**

Run: `.superpowers/tmp/pctest.sh test/metronome/`
Expected: all passed (backing_provider 4 new). Then `flutter analyze` on pc: only the 12 known warnings.

- [ ] **Step 6: Commit**

```bash
git add lib/features/metronome/metronome_engine.dart lib/features/metronome/metronome_provider.dart test/metronome/backing_provider_test.dart
git commit -F .superpowers/tmp/commit_e1_t6.txt   # "feat(Engine): Backing im Engine und Provider — setBacking, Stimmenplan im Loop, Routenwechsel-Zähler"
```

---

### Task 7: Einstellungen, Übungsdaten, Vorschlagsnoten-Fix

**Files:**
- Modify: `lib/data/local/settings_service.dart:60-66` (neben `clickTrackEnabled`)
- Modify: `lib/features/lessons/models/rudiment.dart:205-267`
- Modify: `lib/features/lessons/models/pattern_playback.dart:21-56`
- Modify: `lib/features/practice/practice_session_screen.dart:637-645` (Beat-Log)
- Test: `test/data/settings_backing_test.dart` (neu), `test/lessons/pattern_playback_test.dart` (erweitert)

**Interfaces:**
- Consumes: `backingOff` (Task 2).
- Produces: `SettingsService.backingStyleFor(String exerciseId) → String?`, `setBackingStyleFor(String exerciseId, String? id)`, `SettingsService.backingLevel → double`, `setBackingLevel(double)`; `Rudiment.backing` (String?, default null); `PatternPlayback.isOnsetTick(int tick) → bool`.

- [ ] **Step 1: Write the failing tests**

```dart
// test/data/settings_backing_test.dart
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/metronome/backing_styles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  test('backing style is remembered per exercise, off is explicit', () async {
    expect(SettingsService.backingStyleFor('a'), isNull);
    await SettingsService.setBackingStyleFor('a', 'rock8');
    expect(SettingsService.backingStyleFor('a'), 'rock8');
    expect(SettingsService.backingStyleFor('b'), isNull);
    await SettingsService.setBackingStyleFor('a', backingOff);
    expect(SettingsService.backingStyleFor('a'), backingOff);
    await SettingsService.setBackingStyleFor('a', null);
    expect(SettingsService.backingStyleFor('a'), isNull);
  });
  test('backing level defaults to 0.7 and clamps', () async {
    expect(SettingsService.backingLevel, 0.7);
    await SettingsService.setBackingLevel(0.4);
    expect(SettingsService.backingLevel, 0.4);
    await SettingsService.setBackingLevel(3);
    expect(SettingsService.backingLevel, 1.0);
  });
}
```

Append to `test/lessons/pattern_playback_test.dart` (inside `main`, new group):

```dart
  group('isOnsetTick (measurement takes main notes only)', () {
    test('grace ticks are audible but not onsets', () {
      const beats = [
        StrokeBeat(hand: Hand.left),
        StrokeBeat(hand: Hand.right, isAccent: true, graces: [Hand.left]),
      ];
      final pp = buildPatternPlayback(beats, NoteGrid.quarter);
      expect(pp.tickVolumes[23], graceVolume);
      expect(pp.isOnsetTick(23), isFalse);
      expect(pp.isOnsetTick(24), isTrue);
      expect(pp.isOnsetTick(0), isTrue);
      expect(pp.isOnsetTick(1), isFalse);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/data/settings_backing_test.dart test/lessons/pattern_playback_test.dart`
Expected: FAIL — `backingStyleFor` / `isOnsetTick` undefined.

- [ ] **Step 3: Implement**

`settings_service.dart` (after `setClickTrackEnabled`):

```dart
  /// Backing loop (Engine part 1): the style chosen for one exercise —
  /// null = never chosen (exercise default applies), 'off' = chosen off.
  static String? backingStyleFor(String exerciseId) =>
      _prefs.getString('backing_style_$exerciseId');
  static Future<void> setBackingStyleFor(String exerciseId, String? id) =>
      id == null
          ? _prefs.remove('backing_style_$exerciseId')
          : _prefs.setString('backing_style_$exerciseId', id);

  /// The backing track's own level, global. Default 0.7.
  static double get backingLevel => _prefs.getDouble('backing_level') ?? 0.7;
  static Future<void> setBackingLevel(double v) =>
      _prefs.setDouble('backing_level', v.clamp(0.0, 1.0).toDouble());
```

`rudiment.dart` — field after `collectionGroup`:

```dart
  /// Default backing style id (see `backing_styles.dart`), null = off. The
  /// user's own choice per exercise overrides it.
  final String? backing;
```
constructor: `this.backing,` as the last optional parameter.

`pattern_playback.dart` — method in `PatternPlayback`:

```dart
  /// True when [tick] is a main-note onset. Grace ticks (flam/drag, one or
  /// two ticks before a note) are audible but are not expected strokes for
  /// the measurement — counting them logged phantom notes with the previous
  /// note's index and skewed the hand values.
  bool isOnsetTick(int tick) => onsetTicks.contains(tick);
```

`practice_session_screen.dart` beat log: replace `if (_playback.tickVolumes[tick] > 0) {` with `if (_playback.isOnsetTick(tick)) {` and adjust the comment above to "only main-note onsets (grace ticks sound but are no expected strokes)".

- [ ] **Step 4: Run the tests**

Run: `.superpowers/tmp/pctest.sh test/data/ test/lessons/ test/features/practice/`
Expected: all passed.

- [ ] **Step 5: Commit**

```bash
git add lib/data/local/settings_service.dart lib/features/lessons/models/rudiment.dart lib/features/lessons/models/pattern_playback.dart lib/features/practice/practice_session_screen.dart test/data/settings_backing_test.dart test/lessons/pattern_playback_test.dart
git commit -F .superpowers/tmp/commit_e1_t7.txt   # "feat(Engine): Backing-Einstellungen je Übung, Rudiment.backing, Vorschlagsnoten zählen nicht als Sollnoten"
```

---

### Task 8: Übungs-Screen — Abschnitt BACKING und Kopfhörer-Regel

**Files:**
- Modify: `lib/features/practice/practice_session_screen.dart` (Felder ~116-128, `initState` 130-172, `_applyClickTrack` 323-324, `_showOptionsSheet` 345-395, Modus-Umschaltung ~733, `_OptionsSheet` 1133-1240)
- Test: `test/features/practice/practice_session_screen_test.dart`

**Interfaces:**
- Consumes: `resolveBackingStyle`, `backingStyles`, `backingOff` (Task 2); Provider `setBacking`, `setBackingLevel`, `audioRouteChanges` (Task 6); Settings (Task 7); `AudioCapabilities.headphonesType()` (vorhanden).
- Produces: nichts Neues nach außen.

- [ ] **Step 1: Write the failing tests** (append to `practice_session_screen_test.dart`; add `import 'package:drum_coach/features/metronome/backing_styles.dart';`)

```dart
  /// Mocks the native audio channel: headphone type for the analysis-mode
  /// rule. Returns a handle to change the answer mid-test.
  ({void Function(String) set}) _mockHeadphones(WidgetTester tester, String type) {
    var current = type;
    const channel = MethodChannel('drum_coach/audio');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'headphonesType') return current;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    return (set: (t) => current = t);
  }

  void _mockMicPermission(WidgetTester tester) {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'requestPermissions') return <int, int>{7: 1};
      if (call.method == 'checkPermissionStatus') return 1;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
  }

  testWidgets('options sheet offers backing styles, remembers the choice per '
      'exercise and enables the level slider only with a style',
      (tester) async {
    _mockHeadphones(tester, 'none');
    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('BACKING'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    for (final s in backingStyles) {
      expect(find.text(s.label), findsOneWidget);
    }
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);

    await tester.tap(find.text('Rock 8ths'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    expect(SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock8');
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNotNull);

    await tester.tap(find.text('Off'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(SettingsService.backingStyleFor(rudimentsSeedData.first.id),
        backingOff);
    container.dispose();
  });

  testWidgets('the level slider writes the backing level', (tester) async {
    _mockHeadphones(tester, 'none');
    await SettingsService.setBackingStyleFor(rudimentsSeedData.first.id, 'swing');
    final container = await _pumpScreen(tester, screen: _screen());
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'swing');
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.value, closeTo(0.7, 1e-9));
    slider.onChanged!(0.0);
    await tester.pump();
    expect(SettingsService.backingLevel, 0.0);
    expect(container.read(metronomeNotifierProvider).backingLevel, 0.0);
    container.dispose();
  });

  testWidgets('analysis mode without headphones mutes backing and click track, '
      'with headphones both stay on', (tester) async {
    _mockMicPermission(tester);
    final phones = _mockHeadphones(tester, 'none');
    await SettingsService.setMicAnalysisEnabled(true);
    await SettingsService.setBackingStyleFor(rudimentsSeedData.first.id, 'rock8');

    final container = await _pumpScreen(tester, screen: _screen());
    await tester.pump(); // headphone query answered
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock8');
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    await tester.tap(find.text('LEARN'));
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    // The remembered choice itself is untouched.
    expect(SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock8');

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Off while analysing without headphones — the mic would hear it'),
        findsWidgets);
    await tester.tap(find.text('Rock 16ths'));
    await tester.pump();
    // Choice is stored, but stays muted while the mic listens.
    expect(SettingsService.backingStyleFor(rudimentsSeedData.first.id), 'rock16');
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    await tester.tapAt(const Offset(10, 10)); // close the sheet
    await tester.pumpAndSettle();

    // Headphones plugged in: the metronome reports a route change.
    phones.set('wired');
    container.read(metronomeNotifierProvider.notifier).notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, 'rock16');
    expect(container.read(metronomeNotifierProvider).clickTrack, isTrue);

    // Unplugged again: muted again before the mic hears the band.
    phones.set('none');
    container.read(metronomeNotifierProvider.notifier).notifyAudioRouteChanged();
    await tester.pump();
    await tester.pump();
    expect(container.read(metronomeNotifierProvider).backingStyleId, isNull);
    expect(container.read(metronomeNotifierProvider).clickTrack, isFalse);
    container.dispose();
  });
```

Also update the existing test `'analysis mode silences the click track, learn mode restores it'`: add `_mockHeadphones(tester, 'none');` as its first line (without the mock the channel answers null → 'none' anyway, but explicit is clearer).

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.superpowers/tmp/pctest.sh test/features/practice/practice_session_screen_test.dart`
Expected: FAIL — 'BACKING' not found, `backingStyleId` stays null.

- [ ] **Step 3: Screen state, headphones, `_applyExtras`**

Imports: `import '../metronome/backing_styles.dart';`

Fields (after `late bool _analysisMode = …;`):

```dart
  /// Backing loop (Engine part 1): the remembered/default style for this
  /// exercise; null = off. Applied through [_applyExtras].
  late String? _backingStyleId = resolveBackingStyle(
    stored: SettingsService.backingStyleFor(widget.rudimentId),
    exerciseDefault:
        ref.read(rudimentByIdProvider(widget.rudimentId)).backing,
  );

  /// Headphones detected — the analysis-mode rule: backing and click track
  /// may sound next to the mic only when they cannot reach it.
  bool _headphones = false;
  bool get _extrasAllowed => !_analysisMode || _headphones;
```

Replace `_applyClickTrack` (definition) with:

```dart
  /// Click track and backing follow the settings, the exercise and the
  /// analysis-mode rule (spec §6): both silent while analysing without
  /// headphones, the mic would hear them.
  void _applyExtras() {
    final rudiment = ref.read(rudimentByIdProvider(widget.rudimentId));
    _metronomeNotifier
      ..setClickTrack(SettingsService.clickTrackEnabled && _extrasAllowed)
      ..setBacking(_extrasAllowed ? _backingStyleId : null,
          beatsPerBar: rudiment.beatsPerBar);
  }

  /// Ask the platform for headphones, then re-apply the extras. Failure
  /// counts as "no headphones" (the safe side while the mic listens).
  Future<void> _refreshHeadphones() async {
    var type = 'none';
    try {
      type = await AudioCapabilities.headphonesType();
    } catch (_) {}
    if (!mounted) return;
    _headphones = type != 'none';
    _applyExtras();
  }
```

In `initState`'s post-frame callback replace `_applyClickTrack();` with:

```dart
      metronome.setBackingLevel(SettingsService.backingLevel);
      _applyExtras();
      unawaited(_refreshHeadphones());
```

Every other `_applyClickTrack()` call (options sheet callback, analysis-mode toggle near line 733) becomes `_applyExtras()`; `grep -n _applyClickTrack lib/` must return nothing afterwards.

In `build`, next to the existing `ref.listen<MetronomeState>` for the beat log, add a listener for route changes:

```dart
    ref.listen<int>(
        metronomeNotifierProvider.select((s) => s.audioRouteChanges),
        (prev, next) {
      if (prev != null && next != prev) unawaited(_refreshHeadphones());
    });
```

- [ ] **Step 4: Options sheet — parameters and section**

`_showOptionsSheet`: before `showModalBottomSheet`, `await _refreshHeadphones();`. In the `_OptionsSheet(...)` construction add:

```dart
              backingStyleId: _backingStyleId,
              backingLevel: SettingsService.backingLevel,
              extrasAllowed: _extrasAllowed,
              onBacking: (id) async {
                _backingStyleId = id;
                await SettingsService.setBackingStyleFor(
                    widget.rudimentId, id ?? backingOff);
                _applyExtras();
              },
              onBackingLevel: (level) async {
                await SettingsService.setBackingLevel(level);
                _metronomeNotifier.setBackingLevel(level);
              },
```

`_OptionsSheet`: new constructor params/fields

```dart
    required this.backingStyleId,
    required this.backingLevel,
    required this.extrasAllowed,
    required this.onBacking,
    required this.onBackingLevel,
  …
  final String? backingStyleId;
  final double backingLevel;

  /// False while analysing without headphones: click track and backing are
  /// muted and their controls disabled with a hint.
  final bool extrasAllowed;
  final ValueChanged<String?> onBacking;
  final ValueChanged<double> onBackingLevel;
```

`_OptionsSheetState`: local copies `late String? _backing = widget.backingStyleId; late double _level = widget.backingLevel;` and, directly after the SOUND `Wrap` (before the `const SizedBox(height: 12)` that precedes the click-track switch), the section:

```dart
            const SizedBox(height: 18),
            const _SectionLabel('BACKING'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                AppSelectableChip(
                  label: 'Off',
                  selected: _backing == null,
                  onTap: () {
                    setState(() => _backing = null);
                    widget.onBacking(null);
                  },
                ),
                for (final s in backingStyles)
                  AppSelectableChip(
                    label: s.label,
                    selected: _backing == s.id,
                    onTap: () {
                      setState(() => _backing = s.id);
                      widget.onBacking(s.id);
                    },
                  ),
              ],
            ),
            Row(
              children: [
                Text('Level', style: PracticeTypography.body),
                Expanded(
                  child: Slider(
                    value: _level,
                    min: 0,
                    max: 1,
                    divisions: 10,
                    label: '${(_level * 100).round()} %',
                    onChanged: _backing == null || !widget.extrasAllowed
                        ? null
                        : (v) {
                            setState(() => _level = v);
                            widget.onBackingLevel(v);
                          },
                  ),
                ),
              ],
            ),
            if (!widget.extrasAllowed)
              Text(
                'Off while analysing without headphones — the mic would hear it',
                style: PracticeTypography.body
                    .copyWith(fontSize: 13, color: PracticeColors.textMuted),
              ),
```

Click-track switch: `subtitle` text becomes

```dart
                !widget.extrasAllowed
                    ? 'Off while analysing without headphones — the mic would hear it'
                    : 'A quarter-note pulse next to the exercise',
```
and `onChanged: !widget.extrasAllowed ? null : (on) { … }` (was `widget.analysisMode ? null : …`). The `analysisMode` parameter stays (other uses), but the switch no longer keys on it.

- [ ] **Step 5: Run the practice tests and analyze**

Run: `.superpowers/tmp/pctest.sh test/features/practice/` then `flutter analyze` on pc.
Expected: all passed (3 new), analyzer only the 12 known warnings. If the sheet overflows at 1080×2340 (the tests render at phone size and would throw), the `SingleChildScrollView` already wraps it — check `tester.takeException()` is null in the new tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/practice/practice_session_screen.dart test/features/practice/practice_session_screen_test.dart
git commit -F .superpowers/tmp/commit_e1_t8.txt   # "feat(Engine): Backing-Abschnitt im ⋯-Blatt, Kopfhörer-Regel im Analyse-Modus"
```

---

### Task 9: Doku, Suite, Bericht, Emulator, Draft-PR

**Files:**
- Modify: `docs/CLAUDE.md` (Theme-Abschnitt Zeile ~226 „PracticeSessionScreen (K2 step 2)" und ein neuer Absatz unter „Metronome Implementation Rules" ~275)
- Create: `docs/BERICHT_ENGINE_LOOP.md`

- [ ] **Step 1: Whole suite + analyzer on pc**

Run: `.superpowers/tmp/pctest.sh` (no args) and `flutter analyze` on pc.
Expected: all passed (≈ 338 + 32 new), 12 known warnings.

- [ ] **Step 2: CLAUDE.md**

Under `### Theme (K2)`, in the `PracticeSessionScreen (K2 step 2)` bullet, change `options (duration, sound, click track, about)` to `options (duration, sound, backing style + level, click track, about)`.

Under `## Metronome Implementation Rules` add:

```markdown
- Loop rendering (Engine part 1): `buildLoopPlan` (`loop_voices.dart`) turns
  pattern, click track and a `BackingStyle` (kick + hi-hat, `backing_styles.dart`,
  synthesised in `backing_sounds.dart`) into `LoopVoice`s over one cycle of
  `lcm(pattern, bar)` ticks; `buildLoopWav` mixes them with a soft limiter
  (knee 0.8). Backing only on the 24-tick pattern clock. Analysis-mode rule:
  click track and backing sound only with headphones (the mic would hear them).
  Sound gate: `dart run tool/render_backing_demo.dart <dir>` renders every style.
- Measurement takes main-note onsets only (`PatternPlayback.isOnsetTick`);
  grace ticks (flam/drag) sound but are not expected strokes.
```

- [ ] **Step 3: Bericht** `docs/BERICHT_ENGINE_LOOP.md` — Aufbau wie `BERICHT_K2_RESULT.md`: Was gebaut wurde (Klänge, Stile mit Tabelle, Mischer/Begrenzer/Zyklus, Bedienung, Kopfhörer-Regel, Vorschlagsnoten-Fix), Klang-Gate (Datum, Urteil, Änderungen), Tests (Zahlen), Entscheidungen beim Bauen (aus dem Ledger), Sichtprüfung (Emulator-Screens des ⋯-Blatts), Offen (Bass, Feel der Übung, Fill-Aussetzer, Velocity-Layer, Gerätetest S23 mit Kabel-Kopfhörern).

- [ ] **Step 4: Commit + push**

```bash
git add docs/CLAUDE.md docs/BERICHT_ENGINE_LOOP.md
git commit -F .superpowers/tmp/commit_e1_t9.txt   # "docs(Engine): Bericht Backing-Loop + CLAUDE.md"
git push
```

- [ ] **Step 5: APK + emulator screenshots** (the emulator cannot judge audio; it shows the sheet):

```bash
ssh pc 'cd ~/agent-test-checkouts/drum_coach-k2-result && ~/development/flutter/bin/flutter build apk --release > ~/build-engine-loop.log 2>&1; echo BUILD-EXIT=$? >> ~/build-engine-loop.log'
ssh pc 'export PATH=$HOME/Android/Sdk/platform-tools:$PATH; adb -e install -r ~/agent-test-checkouts/drum_coach-k2-result/build/app/outputs/flutter-apk/app-release.apk'
```
Fahrt mit `emu.sh` (Vordergrund-Check vor jedem Tipp): Today → Start (540,1352) → Practice → „⋯" (Koordinaten aus dem Screenshot) → Screenshot `b1_options` (BACKING-Chips, Level) → Stil tippen → `b2_style` → Off → Kopie `~/k2-practice-screens/emu/`, Seite `backing-emulator.html` wie `result-emulator.html` bauen und veröffentlichen. APK nach `~/drum_coach-engine-loop.apk`.

- [ ] **Step 6: Draft-PR** `engine-loop → k2-result` (gestapelt) mit Spec/Plan/Bericht-Links, Entscheidungen 28.09., Klang-Gate-Urteil, Tests, Seite; Body endet mit `🤖 Generated with [Claude Code](https://claude.com/claude-code)` und der Session-Zeile. Kopien: `~/BERICHT_ENGINE_LOOP.md`.

- [ ] **Step 7: Gerätetest-Bitte** an den Auftraggeber (S23, Kabel-Kopfhörer): Stil wählen, Tempo ändern, Analyse-Modus mit/ohne Kopfhörer, Flam-Übung messen.

---

## Self-Review

**Spec coverage:** §3 Klänge → Task 1. §4 Stile, Auflösung, Kachelung, `beatsPerBar` 2 → Task 2. §5 `LoopVoice`, Begrenzer, lcm, Engine `setBacking`, Provider-State → Tasks 3, 4, 6. §6 Blatt, Einstellungen je Übung, `Rudiment.backing`, Kopfhörer-Regel, Bluetooth-Hinweis (steht im Hinweis-Text nicht — bewusst: der Hinweis nennt nur „headphones"; der Kabel-Rat steht im Bericht/Gerätetest) → Tasks 7, 8. §7 Vorschlagsnoten → Task 7. §8 Fehlerpfade: unbekannte Kennung → Task 2/6; Render-Fehler → Task 6 (try/catch); Kopfhörer-Abfrage-Fehler → Task 8 (`_refreshHeadphones`); Zyklus > 64 Takte → Task 4. §9 Klang-Gate → Task 5. §10 Tests → je Task; §11 Dateien → Dateistruktur; Bericht/CLAUDE.md → Task 9.

**Placeholder scan:** keine TBD/TODO; jeder Code-Schritt trägt Code. Task 9 Schritt 3 beschreibt den Bericht in Gliederung (Prosa-Dokument, kein Code) — zulässig.

**Type consistency:** `LoopVoice(tickVolumes, loudSamples, softSamples, loudFrom, gain)` in Task 3, 4, 5, 6 gleich. `buildLoopPlan(...)`-Parameter in Task 4 (Definition), Task 5 (Tool) und Task 6 (Engine) gleich: `patternVolumes, patternLoud, patternSoft, factor, pulse, pulseSound, backing, backingLevel, beatsPerBar, kickSound, hihatLoud, hihatSoft`. Provider `setBacking(String?, {beatsPerBar})` in Task 6 und Task 8 gleich; `notifyAudioRouteChanged()` in Task 6 und Task 8 gleich. `resolveBackingStyle({stored, exerciseDefault})` in Task 2 und 8 gleich. `backingOff` in Task 2, 7, 8 gleich.

**Review Focus:** alle fünf Zeilen haben ihren Test im genannten Task (1 → Task 4 Test „Zyklus Vielfaches" + Task 6; 2 → Task 2; 3 → Task 8 dritter Test; 4 → Task 3 `gain: 0` + Task 8 Slider 0; 5 → Task 2 `beatsPerBar: 2`).
