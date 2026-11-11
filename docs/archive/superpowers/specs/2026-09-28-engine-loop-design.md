# Design-Spec: Engine Teil 1 — Backing-Loop (Hör-Loop Kick + Hi-Hat)

Datum 28.09.2026 · Branch `engine-loop` (gestapelt auf `k2-result`) · Status:
Entwurf vom Auftraggeber freigegeben (28.09.), Spec zur Prüfung.

Vorlage: `docs/concept/BRIEF_PAD_UEBUNGEN.md` §5 Punkt 1, §7 Schritt 2, §8.
Engine-Phase = drei Teile in dieser Reihenfolge: **Loop (dieser Teil)**,
Dynamik, Messung. Jeder Teil mit eigener Spec, Plan, Bau und Gerätetest.

## 0. Entscheidungen des Auftraggebers (28.09.)

> **Nachtrag 28.09. nachmittags (nach dem Bau):** „Ich möchte den Backing-
> Track nicht auswählen müssen. Er soll einfach automatisch zur Übung
> passen." → Keine Stil-Wahl im Blatt mehr; ein Schalter „Backing" (Standard
> an, global) plus Level-Regler; der Stil kommt aus `autoBackingStyle`
> (§6a). Außerdem: „Das Hintergrundbild kann man kaum erkennen" → Schleier
> über dem Übungs-Foto von 55/78/94 % auf 30/60/88 % zurückgenommen.

1. Reihenfolge Loop → Dynamik → Messung.
2. Der Backing-Loop ist **nur zum Hören** (Band aus dem Handy). Gespielt wird
   weiter **einstimmig am Pad**. Übungen fürs Set sind der nächste Bauabschnitt.
3. Besetzung des Hör-Loops: **Kick + Hi-Hat**. Bass später als dritte Stimme.
4. Katalog-Zielgröße 12 Rudiments / 8 Fill-Stickings / 6 Stücke (gilt für die
   Katalog-Phase, hier nur festgehalten).
5. Bauweise 1 (eine gerenderte Schleife mit mehreren Stimmen), synthetische
   Klänge, **Klang-Gate** vor dem UI-Bau, Gerätetest am S23 mit Kopfhörern.

## 1. Ziel und Nicht-Ziele

**Ziel.** Zu jeder Pad-Übung kann eine kleine Band aus Kick und Hi-Hat
mitlaufen: sample-genau synchron zum Muster, in jedem Tempo ohne Zeitdehnung,
mit eigener Lautstärke, wählbar aus einem kleinen Stil-Vorrat, pro Übung
gemerkt. Das ist die Voraussetzung für die Fill-Stickings (3 Takte Time,
1 Takt Fill; der Puls läuft im Fill-Takt weiter) und macht Drills und Stücke
musikalischer. Nebenbei wird ein bekannter Messfehler behoben: Vorschlagsnoten
(Flam, Drag) zählen nicht mehr als eigene Sollnoten.

**Nicht-Ziele.** Bass-Stimme. Dynamikstufen im Muster (Teil 2). Mess-
Korrekturen außer dem Vorschlagsnoten-Fix (Teil 3). Änderungen an der Notation.
Loops aus Song-Ausschnitten oder Audio-Dateien. Ein Lautstärke-Regler fürs
Muster selbst. Ein Aussetzen der Band im Fill-Takt (Brief 3.2: der Puls läuft
weiter). Neue Übungen (Katalog-Phase).

## 2. Begriffe

- **Tick:** 1/24 Viertelnote, das Raster von `PatternPlayback` und Renderer.
- **Zyklus:** die eine Tondatei, die die App rendert und als Endlosschleife
  spielt; heute Muster plus Viertelpuls.
- **Stimme:** eine Spur im Zyklus mit eigenen Schlägen, Klängen und Pegel.
  Nach diesem Teil: Muster, Klick-Spur (Puls), Kick, Hi-Hat.
- **Stil:** ein Takt Kick und Hi-Hat auf dem Tick-Raster plus Feel.
- **Feel:** gerade, Shuffle, Swing — nur eine Eigenschaft des Stils; das Feel
  der Übung selbst kommt in Teil 2/3.

## 3. Klänge — `lib/features/metronome/backing_sounds.dart`

Synthetisch wie Klick und Rim (`MetronomeEngine.synthSamples`), damit keine
Samples, keine Lizenzen und keine Assets nötig sind. Reine Funktionen, 44,1 kHz,
Werte als `List<double>` in −1…1, deterministisch (Rauschen aus einem festen
Zufallsgenerator, damit zwei Aufrufe identisch sind und Tests stabil bleiben).

- `kickSamples({int sampleRate = 44100})`: ~180 ms. Sinus, dessen Frequenz in
  den ersten 60 ms exponentiell von 150 Hz auf 48 Hz fällt, Hüllkurve
  exponentiell abklingend, dazu ein 2-ms-Anschlag (kurzer Rauschimpuls), damit
  der Kick auch auf kleinen Lautsprechern ortbar ist. Spitze ≤ 0,9.
- `hihatSamples({required bool accent, int sampleRate = 44100})`: weißes
  Rauschen durch einen einfachen Hochpass (Differenz-Filter), exponentiell
  abklingend. Geschlossen (`accent: false`): ~60 ms, Spitze 0,5. Akzent
  (`accent: true`, „leicht offen"): ~160 ms, langsamer abklingend, Spitze 0,65.

Tests (`test/metronome/backing_sounds_test.dart`): Länge ±5 % vom Soll, Spitze
in [0,3; 0,95], nicht leer, zwei Aufrufe identisch; Kick hat eine
Nulldurchgangsrate unter 400/s (tiefer Ton), Hi-Hat über 3000/s (Rauschen);
Hi-Hat-Akzent länger als geschlossen.

## 4. Stil-Vorrat — `lib/features/metronome/backing_styles.dart`

```dart
enum BackingFeel { straight, shuffle, swing }

class BackingHit {
  final int tick;      // 0..95 innerhalb eines 4/4-Takts (24 Ticks je Viertel)
  final double level;  // 0 < level ≤ 1; Hi-Hat ≥ 0.9 nimmt den Akzent-Klang
  const BackingHit(this.tick, this.level);
}

class BackingStyle {
  final String id;          // stabil, in Einstellungen und Übungsdaten gespeichert
  final String label;       // Anzeige, Englisch
  final BackingFeel feel;
  final List<BackingHit> kick;
  final List<BackingHit> hihat;
  const BackingStyle({...});
}

const backingStyles = <BackingStyle>[...];        // Reihenfolge = Anzeige
BackingStyle? backingStyleById(String? id);       // null oder unbekannt → null
```

Sechs Stile, ein Takt 4/4. Schreibweise: Viertel 1–4, `&` = Achtel dazwischen,
`e`/`a` = Sechzehntel, `t` = dritte Triole (Tick 16 im Viertel).

| id | label | feel | Kick | Hi-Hat |
|---|---|---|---|---|
| `rock8` | Rock 8ths | straight | 1, 3 | alle Achtel; Viertel 1,0, `&` 0,7 |
| `rock16` | Rock 16ths | straight | 1, 3, `&` von 3 | alle Sechzehntel; Viertel 1,0, `&` 0,7, `e`/`a` 0,5 |
| `halftime` | Half-time | straight | 1, `&` von 2 | alle Achtel; 1 und 3 mit 1,0, Rest 0,6 |
| `shuffle` | Shuffle | shuffle | 1, 3 | je Viertel Tick 0 (1,0) und Tick 16 (0,6) |
| `swing` | Swing | swing | 1, 2, 3, 4 mit 0,4 (leise „Feder") | 1 (1,0) · 2 (1,0) + `t` von 2 (0,6) · 3 (1,0) · 4 (1,0) + `t` von 4 (0,6) |
| `funk16` | Funk 16ths | straight | 1, `a` von 1, `&` von 2, 3, `a` von 3 | alle Sechzehntel; Achtel 0,8, `e`/`a` 0,45, Viertel 1,0 |

Diese Muster sind Daten und werden im Klang-Gate (§9) mit dem Auftraggeber
abgestimmt; Änderungen dort ändern nur diese Tabelle und Datei.

Takte mit `beatsPerBar` ≠ 4: der Stil wird je Takt gekachelt und auf
`beatsPerBar × 24` Ticks beschnitten (Schläge mit `tick ≥ beatsPerBar × 24`
entfallen). Mehr als 4 Viertel je Takt gibt es im Katalog nicht.

Tests (`test/metronome/backing_styles_test.dart`): ids eindeutig und nicht
leer, alle Ticks in 0..95, alle Pegel in (0; 1], jeder Stil hat einen Hi-Hat-
Schlag auf Tick 0 (die Eins ist immer hörbar), `backingStyleById` liefert null
für null und Unbekanntes.

## 5. Mischer — `lib/features/metronome/click_loop_renderer.dart`

Der Renderer wird von „Muster plus Puls" auf eine Liste von Stimmen umgebaut.

```dart
class LoopVoice {
  final List<double> tickVolumes;  // Länge = Zyklus-Ticks, 0 = kein Schlag
  final List<double> loudSamples;  // Klang ab [loudFrom]
  final List<double> softSamples;  // Klang darunter
  final double loudFrom;           // Muster 1.2 (Akzent), Hi-Hat 0.9, sonst 1.0
  final double gain;               // Spur-Lautstärke 0..1
}

Uint8List buildLoopWav({
  required int bpm,
  required int factor,             // Ticks je Viertel (24)
  required List<LoopVoice> voices,
  int sampleRate = 44100,
});
```

- Jede Stimme: Klang × `tickVolume` × `gain`, additiv in den Zyklus gemischt
  (Umlauf ans Zyklusende wie heute). Alle Stimmen haben dieselbe Länge; der
  Renderer prüft das (`ArgumentError`).
- Die alte Signatur (`tickVolumes/accentSamples/normalSamples/pulseSamples/
  pulseEvery`) entfällt; die eine Aufrufstelle im Engine und die Renderer-
  Tests werden umgestellt. Muster = `LoopVoice(loudFrom 1.2, gain 1)`, Puls =
  `LoopVoice` mit 1,0 auf jedem `factor`-ten Tick, Kick und Hi-Hat aus dem
  Stil (§6).
- **Begrenzer statt hartem Abschneiden:** bis |x| ≤ 0,8 linear, darüber weich
  (`0.8 + 0.2·tanh((|x|−0.8)/0.2)`), Ergebnis immer < 1,0. Eine Stimme allein
  klingt bis 0,8 exakt wie heute; der Akzent-Klick (heute 1,9 → hart auf 1,0
  geschnitten) wird weich begrenzt. Tests prüfen: vier volle Stimmen zusammen
  ergeben keine zwei aufeinanderfolgenden Werte ≥ 0,99 (kein Flat-Top).
- **Zykluslänge:** `lcm(patternTicks, beatsPerBar × 24)`. Heute ist der Zyklus
  genau das Muster; 19 der 41 Basis-Rudiments sind kürzer als ein Takt, dort
  wiederholt sich das Muster im Zyklus, damit der Stil-Takt ganz bleibt.
  `PatternPlayback.totalTicks` bleibt die Musterlänge; Marker, Beat-Log und
  Notenindex rechnen weiter `globalTick % totalTicks` und bleiben korrekt,
  weil der Zyklus ein Vielfaches davon ist. Ohne Backing bleibt der Zyklus die
  Musterlänge (kein Verhalten ändert sich).

Engine (`metronome_engine.dart`): neue Felder `_backing` (`BackingStyle?`),
`_backingLevel` (double), `_beatsPerBar` (int), Methode
`setBacking(BackingStyle? style, {required double level, required int
beatsPerBar})` → `_scheduleLoopRebuild`. `_startLoop` baut die Stimmenliste.
Der Beat-Poller und die Uhr bleiben unverändert; die Musterstimme behält die
Zykluslänge für die Tick-Uhr.

Provider (`metronome_provider.dart`): `MetronomeState` bekommt
`backingStyleId` (String?) und `backingLevel` (double); `setBacking(String?
id)`, `setBackingLevel(double)`. Beides wird an den Engine durchgereicht.

## 6. Bedienung im Übungs-Screen

- **„⋯"-Blatt** (Nachtrag 28.09., ersetzt die Stil-Chips): unter `SOUND` ein
  Schalter „Backing" mit der Zeile „<Stil> · automatic" (Standard an, global
  gemerkt) und darunter der Slider „Level" 0–100 % in 10er-Schritten, nur
  aktiv, wenn der Schalter an ist.
- **Einstellungen** (`SettingsService`): `backingEnabled` /
  `setBackingEnabled` (global, Standard an), `backingLevel` /
  `setBackingLevel` (global, Standard 0,7).
- **Übungsdaten:** `Rudiment.backing` (String?, Standard null) als
  ausdrückliche Vorgabe für den Katalog; sonst greift §6a.

### 6a. Automatischer Stil — `lib/features/practice/auto_backing.dart`

`String autoBackingStyle(Rudiment r, {required int bpm})`, reine Funktion,
bei jedem Anwenden (Start, Tempoänderung, Modus-/Kopfhörer-Wechsel) neu
ausgewertet:

| Übung | Stil |
|---|---|
| `r.backing` ist eine bekannte Kennung | genau der |
| Genre Jazz | `swing` |
| Genre Funk | `funk16` |
| Triolen-Raster oder Triolen/Sextolen im Muster | `shuffle` |
| Sechzehntel-Raster (≥ 4 Zellen je Viertel) oder Sechzehntel/32tel-Werte im Muster | `rock16`, ab 140 BPM `rock8` |
| alles andere | `rock8` |

`halftime` bleibt im Vorrat für ausdrückliche Vorgaben.
- **Kopfhörer-Regel:** Das Mikro würde Band und Klick-Spur mithören.
  Kopfhörer = `AudioCapabilities.headphonesType() != 'none'`, abgefragt beim
  Screen-Start und bei jedem Kopfhörer-Wechsel, den das Metronom als
  Routenwechsel meldet; bei einem Routenwechsel wird sofort pessimistisch
  stummgeschaltet, bis die Abfrage antwortet (Review-Fix 28.09.).
  - **Backing** läuft **nur mit Kopfhörern, sobald das Mikro überhaupt
    mithört** (Mikro-Analyse eingeschaltet, Lern- wie Analyse-Modus): die
    Band ist laut genug, um als Schläge zu zählen, und auch das Lern-Ergebnis
    zeigt Treffer und Timing (Review-Ruling 28.09.). Mit ausgeschalteter
    Mikro-Analyse (Standard) spielt die Band frei.
  - **Klick-Spur** behält die Regel vom 27.09.: im Analyse-Modus nur mit
    Kopfhörern, im Lern-Modus immer erlaubt (kurzer, leiser Puls).
  - Im Blatt: Backing-Schalter und Level-Regler sind gesperrt, die Zeile
    unter dem Schalter sagt „Off while the mic listens without headphones —
    it would hear the band". Für die Klick-Spur ist der Schalter gesperrt
    mit „Off while analysing without headphones — the mic would hear it".
  Bekannte Grenze: Bluetooth-Kopfhörer verzögern das Gehörte um bis zu ~200 ms;
  die Latenz-Kalibrierung deckt das nicht ab, Kabel wird im Hinweis empfohlen.
- **Sonst unverändert:** Kopfzeile, Notenblatt, Pulsbalken (zeigt weiter nur
  das Muster), Hauptknopf, Ergebnis-Blatt.

## 7. Vorschlagsnoten-Fix (Messung)

Heute nimmt das Beat-Log jeden Tick mit `tickVolumes[tick] > 0` als Sollnote,
also auch die Vorschläge von Flam und Drag (Pegel 0,25, ein Tick vor der
Hauptnote); `noteIndexAtTick` ordnet sie der vorherigen Note zu — falsche Hand,
falsche Position, verzerrte Hand-Werte. Neu: `PatternPlayback.isOnsetTick(tick)`
(Menge der Hauptnoten-Ticks); das Beat-Log im Screen nimmt nur diese. Der
Beat-Poller des Engines sendet weiter Ereignisse für alle hörbaren Ticks
(Marker, Cursor). Test: Muster mit Flam → Beat-Log hat genau einen Eintrag je
Hauptnote mit richtigem Notenindex.

## 8. Fehlerpfade

- Stil-Kennung unbekannt (alte Einstellung, Tippfehler in Übungsdaten) →
  wie Off, kein Fehler.
- Rendern der Backing-Stimmen wirft (z. B. Längen passen nicht) → der Engine
  rendert den Zyklus ohne Backing, `debugPrint`, die Übung läuft.
- Kopfhörer-Abfrage schlägt fehl → gilt als „keine Kopfhörer" (sichere Seite
  im Analyse-Modus).
- Zykluslänge über 64 Takten (kein Katalog-Fall) → Backing aus, `debugPrint`.

## 9. Klang-Gate (vor dem UI-Bau)

Ein kleines Dart-Werkzeug `tool/render_backing_demo.dart` rendert jeden Stil bei
90 BPM für 8 Takte (~21 s) mit einem Achtel-Muster R L (Klick-Klang) und
einmal ohne Muster, als WAV nach `~/backing-demo/<id>.wav` bzw.
`<id>_solo.wav`; Lauf auf der GPU-Box, Kopie ins Home des Auftraggebers. Er
hört am Laptop oder Handy und urteilt: klingt nach Band, Pegelverhältnis
passt, Stile unterscheidbar. Nachbesserungen betreffen nur §3 und §4. Erst
nach dem Ja werden Engine-Anbindung, Blatt und Einstellungen gebaut.

## 10. Tests

- `test/metronome/backing_sounds_test.dart` (§3), `backing_styles_test.dart`
  (§4).
- `test/metronome/click_loop_renderer_test.dart`: Umstellung auf `LoopVoice`;
  neu: mehrere Stimmen mischen additiv, `gain` wirkt, Längenprüfung wirft,
  Begrenzer (kein Flat-Top, eine Stimme bis 0,8 unverändert), Zykluslänge
  = lcm, Kachelung eines Stils über mehrere Takte und bei `beatsPerBar` 2.
- `test/metronome/`: Engine/Provider — `setBacking` löst Rebuild aus, Zyklus
  ohne Backing bleibt Musterlänge, Tick-Uhr bleibt monoton beim Umschalten.
- `test/data/`: Einstellungen `backingStyleFor`/`backingLevel` bleiben
  erhalten.
- `test/lessons/pattern_playback_test.dart`: `isOnsetTick` bei Flam/Drag.
- `test/features/practice/practice_session_screen_test.dart`: Blatt zeigt
  Schalter „Backing" mit „<Stil> · automatic", keine Chips; Schalter aus →
  Band aus, Regler gesperrt; Stil folgt dem Tempo (Sechzehntel → Achtel ab
  140 BPM); Mikro hört mit ohne Kopfhörer → Backing stumm, Schalter und
  Regler gesperrt, Hinweis, Klick-Spur im Analyse-Modus gesperrt; mit
  Kopfhörern (Kanal gemockt) → aktiv; Routenwechsel schaltet sofort stumm,
  bevor die Abfrage antwortet; Beat-Log ohne Vorschlags-Ticks.
  `test/features/practice/auto_backing_test.dart`: jede Regel-Zeile.
- Gerätetest S23 mit Kabel-Kopfhörern: Stil wählen, Tempo ändern (Loop bleibt
  synchron), Analyse-Modus mit und ohne Kopfhörer, Flam-Übung messen (Hand-
  Werte plausibel), Marker läuft weiter richtig.

## 11. Dateien

- Neu: `lib/features/metronome/backing_sounds.dart`, `backing_styles.dart`,
  `tool/render_backing_demo.dart`, Tests wie in §10.
- Ändern: `click_loop_renderer.dart` (LoopVoice, Begrenzer, lcm),
  `metronome_engine.dart` (setBacking, Stimmenliste), `metronome_provider.dart`
  (State + Setter), `lib/features/lessons/models/rudiment.dart` (`backing`),
  `pattern_playback.dart` (`isOnsetTick`), `lib/data/local/settings_service.dart`,
  `lib/features/practice/practice_session_screen.dart` (Blatt, Kopfhörer-
  Regel, Beat-Log), `docs/CLAUDE.md` (Engine-Abschnitt), Bericht
  `docs/BERICHT_ENGINE_LOOP.md`.

## 12. Offen / spätere Teile

- Bass als dritte Stimme (Entscheidung 3).
- Feel der Übung selbst und feel-bewusste Jitter-Sperre (Teil 3).
- Aussetzer der Band im Fill-Takt als Option — nur, wenn der Auftraggeber es
  nach dem Gerätetest wünscht.
- Velocity-Layer für die Snare (Brief §5 Punkt 6).
