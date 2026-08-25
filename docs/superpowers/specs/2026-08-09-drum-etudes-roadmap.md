# Roadmap: Komplexe Mehrtakt-Übungen + adaptives Trainingsprogramm

**Datum:** 2026-08-09
**Branch:** `feature/drum-etudes`
**Status:** Design validiert, Specs in Arbeit

## Kontext

Der Nutzer möchte komplexere, mehrtaktige Übungen für das Drum-Pad in der App —
inspiriert von Drumeos „Easy Rudiments"-Heft (im Repo als
`Easy-Rudiments-Interactive-PDF_260809_215241.pdf`, © 2023 Musora Media Inc.).
Das PDF dient nur als **Vorbild**; seine Übungen sind urheberrechtlich geschützt
und werden **nicht kopiert**. Stattdessen werden **eigene, originale** Übungen
gesetzt, aufbauend auf den gemeinfreien Standard-Rudiments (PAS) und darüber
hinausgehenden Übungstypen.

Zusätzlich soll das bestehende fixe 84-Tage-Trainingsprogramm durch ein
**konfigurierbares, adaptives** Programm ersetzt werden.

## Warum das nötig ist

Das heutige Übungs-Modell (`Rudiment` in
`lib/features/lessons/models/rudiment.dart`) kennt **eine** Subdivision pro Übung
(ein `StrokeBeat` = ein Metronom-Tick). Musikalische Lese-Étuden mit **gemischten
Notenwerten** (Viertel + Achtel + Sechzehntel + Triole in einer Zeile) sind damit
nicht darstellbar. Das ist die Grundlage, die zuerst geschaffen werden muss.

Das Trainingsprogramm ist ein einzelnes, fest verdrahtetes 84-Tage-Programm
(`trainingProgramProvider` liefert immer die const `stickControlProgram`), ohne
Wahl von Zeitraum, Startschwierigkeit oder Inhalt.

## Locked Decisions (mit dem Nutzer abgestimmt)

- **Original-Inhalte**, kein Kopieren des PDFs (Urheberrecht).
- **Musikalische Lese-Étuden** mit gemischten Notenwerten → Engine-Umbau nötig.
- **Timing:** Feinraster-Quantisierung (24 Ticks/Viertel) über das vorhandene
  `setPatternVolumes`; das Timing-Isolate in `metronome_engine.dart` bleibt
  unangetastet. **Kein** Event-Scheduler-Umbau.
- **Modell:** lesbares `NoteValue`-Enum + explizite Tuolen (statt roher Ticks).
- **Sammlung:** die neuen Übungen erscheinen als benannte, browsebare Sammlung.
- **Ergänzende Übungstypen** (nicht nur ein Rudiment): Akzent-/Dynamik-Studien,
  Kombinations-/Koordinationsstücke, Roll-/Endurance-Étuden. (Reines Blattlesen
  als eigener Typ entfällt — Lesen steckt in der gemischten Notation.)
- **Umfang Inhalte:** ~10 Rudiments als Basis + ergänzende komplexe Übungen.
- **Adaptives Programm:** Zeitraum wählen (= **Pacing-Ziel**, echt adaptiv),
  Startschwierigkeit, Inhalts-Pool (neue Übungen / klassische Schlagübungen),
  Steigerung wenn User bereit.
- **Reihenfolge:** SP1 → SP2/SP3 → SP4.
- **Mic-Analyse** (`mic_analysis_service`) wird in SP1 **nicht** mitgezogen
  (sie nimmt „ein Schlag = ein Tick" an); separater Folgeschritt.

## Bausteine

| # | Baustein | Kern | Hängt an | Eigene Spec |
|---|----------|------|----------|-------------|
| **SP1** | Notations-Engine (echte Notenwerte) | Modell + Renderer + Playback für gemischte Rhythmen | — | `2026-08-09-notation-engine-note-values-design.md` |
| **SP2** | Benannte Sammlung | `collection`-Feld auf `Rudiment` + Browse-Screen | — | (folgt) |
| **SP3** | Inhalte | ~10 Rudiment-Étuden + Akzent-/Kombi-/Roll-Étuden | SP1 | (folgt) |
| **SP4** | Adaptives Trainingsprogramm | Zeitraum/Startschwierigkeit/Pool + Reife-Gate | SP2/SP3 (nur „neue Übungen"-Pool) | (folgt) |

Jeder Baustein durchläuft eigenständig **Spec → Plan → Umsetzung**. Diese Roadmap
ist die Klammer; SP1 wird zuerst vollständig spezifiziert und umgesetzt.

### SP2 — Benannte Sammlung (Kurzskizze)

- Neues optionales Feld auf `Rudiment`, z. B. `String? collection` (oder ein
  `enum ExerciseCollection`), das eine browsebare Gruppe benennt.
- Einfacher Sammlungs-Screen (Liste der Übungen einer Sammlung) + Router-Eintrag.
- Dient gleichzeitig als Filter-Grundlage für den „neue Übungen"-Pool in SP4.

### SP3 — Inhalte (Kurzskizze)

- ~10 Rudiment-Étuden (Paradiddles, Flam Accent, Drag, Five/Nine Stroke Roll,
  Swiss Triplet, …) als mehrtaktige, originale Übungen auf der SP1-Engine.
- Ergänzend: Akzent-/Dynamik-Studien, Kombinations-/Koordinationsstücke,
  Roll-/Endurance-Étuden.
- Alle als `Rudiment`-Einträge in `rudiments_seed.dart` mit **eindeutigen ids**
  (die vorhandenen Duplikate `paradiddle_diddle`, `flam_accent`,
  `flam_paradiddle` werden dabei mitbereinigt), passenden Tags und
  `collection`-Zuordnung.
- Authoring-Helfer (DSL) aus SP1 machen das Setzen der vielen Étuden lesbar.

### SP4 — Adaptives Trainingsprogramm (Kurzskizze)

Ersetzt das fixe 84-Tage-Programm. Die vier Nutzer-Anforderungen → Code:

1. **Zeitraum** (Pacing-Ziel): `programTotalDays` parametrisieren (heute const in
   `program_provider.dart`; das Modell `TrainingProgram` ist bereits generisch).
   Der Schwierigkeits-Bogen wird über den gewählten Zeitraum als Richtwert
   verteilt; der User kann schneller/langsamer vorankommen.
2. **Startschwierigkeit:** über das vorhandene `Difficulty`-Enum + Start-Tempoband.
3. **Inhalts-Pool:** `enum ProgramPool { basicStrokes, newExercises, mixed }` über
   das vorhandene `filterRudiments`. `basicStrokes` funktioniert sofort;
   `newExercises` zieht aus der SP2-Sammlung.
4. **Adaptive Steigerung:** neue, reine **Reife-Gate-Funktion** auf Basis der
   vorhandenen Signale (`RudimentProgress.mastery` = bestBpm/targetBpm,
   Clean-Pass, Spaced Repetition). Sind die Übungen der aktuellen Stufe
   „graduiert", wird auf die nächste Stufe/Übung/Tempoband befördert.

- **Persistenz:** neue `ProgramConfig` (Zeitraum/Startschwierigkeit/Pool) statt
  nur des Start-Datums in `SettingsService`.
- **UI:** Setup-Screen (`/program/setup`) vor `ProgramController.start()`; die
  Tages-Ansicht (`_DayView`) bleibt weitgehend.
- Das alte Programm wird ein Preset (basicStrokes, ~12 Wochen, beginner) — oder
  entfällt.

## Verifikation (übergreifend)

Diese Maschine (NUC, headless) kann keine Flutter-UI rendern. Sichtprüfung und
Gerätetests laufen über die `cross-machine-test-deploy`-Skill auf PC/Laptop bzw.
einem angeschlossenen Android-Gerät (S23 Ultra, wie bei PR #7). Reine Logik
(Dauer-/Onset-/Tuolen-Mathematik, Reife-Gate) wird per Unit-Test auf dieser
Maschine abgesichert.
