# Bericht Etappe 1 — §0 Bestandsaufnahme

**Datum:** 06.09.2026 · **Auftrag:** §0 aus `docs/BRIEF_ETAPPE1_PAD.md` · **Kein Code geändert.**

**Untersuchte Stände:** Der Brief nennt als Ausgangsbasis „PR #14 (gemergt)".
Tatsächlich ist **PR #14 offen (Draft)**; `origin/main` steht auf dem Merge von
PR #10 (`61c5b3e`, 25.08.2026). Die Antworten unten beschreiben deshalb beide
Stände: **main** (`origin/main`) und **#14** (Branch `worktree-fix+program-ux-mic`,
PR #14). Wo nichts vermerkt ist, sind beide Stände gleich. Details unter
[Widersprüche & Rückfragen](#widersprüche--rückfragen).

---

## Frage 1 — Hand-Zuordnung

**Verfahren: zeitliche Nächste-Nachbar-Suche, kein Sequenzabgleich.** Jeder
erkannte Onset wird dem zeitlich nächsten erwarteten Beat zugeordnet, mit
250 ms als Obergrenze; ein Abgleich, der Auslassungen oder Einfügungen als
solche erkennt, existiert nicht.

- main: Schleife über alle Beats pro Hit, `minDist = 250` —
  `lib/features/coaching/services/mic_analysis_service.dart:98-111`
- #14: gleiches Prinzip als Zwei-Zeiger-Lauf über die chronologischen Listen,
  Abbruch bei ≥ 250 ms — `mic_analysis_service.dart:81-94` (Stand #14)

Die Hand kommt ausschließlich aus dem Sticking der zugeordneten Position:
`sticking[nearest.beatIndex % sticking.length].hand`
(main `mic_analysis_service.dart:114-115`, #14 `:95-100`).

**Auf main ist die Zuordnung darüber hinaus defekt.** Der Practice-Screen
fährt das Metronom mit einem Pattern-Clock von 24 Ticks pro Viertelnote
(`lib/features/practice/practice_session_screen.dart:74-76`,
`lib/features/lessons/models/pattern_playback.dart:48-56`). Der
Metronom-Notifier übernimmt jeden Tick als `currentBeatIndex`
(`lib/features/metronome/metronome_provider.dart:73-79`; BeatEvent pro Tick:
`lib/features/metronome/metronome_engine.dart:220-224`), und das `beatLog`
protokolliert jeden Indexwechsel (`practice_session_screen.dart:225-235`).
Folgen auf main:

- `beatIndex` ist ein **Tick-Index**, `beatIndex % sticking.length` hat keinen
  Bezug zur Notenposition — die abgeleitete Hand ist praktisch beliebig.
- `expectedHits = beatLog.length` zählt Ticks statt Soll-Schläge
  (`mic_analysis_service.dart:143`) — bei Viertelnoten 24-fach überhöht.
- Der zeitlich nächste „Beat" ist immer ein Tick im 25-ms-Raster (bei
  100 BPM), die gemessene Abweichung ist dadurch auf ±½ Tick (~12,5 ms)
  gedeckelt — die Timing-Werte sind systematisch geschönt.

**#14 behebt genau das:** geloggt werden nur Ticks mit Anschlag
(`tickVolumes[tick] > 0`), und als `beatIndex` wird der **Noten-Index**
gespeichert (`practice_session_screen.dart:411-418`, Stand #14). Dort ist die
Hand-Ableitung semantisch korrekt.

**Fehlender Schlag (Stand #14):** Die erwartete Note bleibt einfach ohne
Zuordnung; es wird weder gezählt noch gemeldet. Nachfolgende Onsets matchen
weiterhin ihre zeitlich nächste Note — die Hände verschieben sich also
**nicht** (solange der Spieler nicht mehr als eine halbe Notendauer daneben
liegt). **Zusätzlicher Schlag:** auch er bekommt die zeitlich nächste Note
zugewiesen — Noten werden beim Matching nicht „verbraucht", Mehrfachzuordnung
derselben Note ist möglich — und erhält deren Hand; als „überzählig" wird
nichts ausgewiesen. Onsets weiter als 250 ms von jeder Note entfernt fallen
stillschweigend weg (`mic_analysis_service.dart:94`, Stand #14). Die einzige
globale Soll/Ist-Information ist `detectedHits` vs. `expectedHits`
(`lib/features/coaching/models/session_analysis.dart:6-7`).

→ Damit ist das in Brief §1.2 geplante Alignment mit Auslassungs-/
Einfügungs-Erkennung tatsächlich Neuland. Zum Widerspruch mit der
§1.2-Abnahme („Vorher: Hände vertauscht") siehe unten.

## Frage 2 — Aufnahmeweg

**Plugin:** `record` 7.1.1 (`pubspec.yaml:26`; Android-Implementierung
`record_android` 2.1.2). Aufnahme als PCM-Stream:
`startStream(RecordConfig(encoder: pcm16bits, sampleRate: 16000, numChannels: 1))`
— `mic_analysis_service.dart:33-37` (auf #14 unverändert).

**AudioSource:** Es wird **keine** `androidConfig` übergeben, also gilt der
Plugin-Default `AndroidAudioSource.defaultSource` =
`MediaRecorder.AudioSource.DEFAULT`
(`record_platform_interface-2.1.0/lib/src/types/android_record_config.dart:57`).

**Effekte:** `autoGain`, `echoCancel`, `noiseSuppress` stehen im Plugin per
Default auf `false` (`record_config.dart:84-86`) — die App **fordert sie nicht
an**. Sie werden aber auch nicht ausdrücklich abgeschaltet, und bei der Quelle
`DEFAULT` kann die Geräte-Signalkette (Samsung) eigene Verarbeitung
enthalten. Der in Brief §1.1 geforderte rohe Weg (UNPROCESSED bzw.
VOICE_RECOGNITION mit explizit deaktivierten Effekten) ist heute nicht
umgesetzt — erwartungsgemäß, das ist ja der Phase-1-Auftrag.

**UNPROCESSED:** Das Plugin unterstützt die Quelle ab Android N
(`record_android-2.1.2/.../record/model/RecordConfig.kt:76-78`), die App nutzt
sie nicht. Eine Laufzeitprüfung, ob das Gerät sie anbietet
(`PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED`), gibt es nirgends — **ob das
S23 Ultra UNPROCESSED liefert, ist aus dem Code nicht feststellbar** und muss
der Phase-1-Gerätetest klären.

**Verstärkung:** Nirgends gesetzt; es gibt keinerlei Gain-Steuerung im Code.
Es gilt, was die DEFAULT-Quelle liefert.

**Zusatzbefund (main):** Die Onset-Erkennung auf main stempelt mit
`DateTime.now()` pro 10-ms-Fenster (`mic_analysis_service.dart:63,70`). Da
Audio in gebündelten Chunks ankommt, kollabieren alle Fenster eines Chunks auf
denselben Zeitpunkt, und die 100-ms-Sperre schluckt alle Hits eines Chunks bis
auf den ersten — so benennt es der Kommentar des #14-Detektors selbst
(`onset_detector.dart:13-18`, Stand #14). Die Mic-Messung auf main ist also
auch jenseits der Hand-Frage nicht belastbar.

## Frage 3 — Zeitbasis

**Drei Uhren, nur über die Wanduhr verbunden; keine Latenz-Korrektur.**

- **Klick-Erzeugung:** Timing-Isolate mit monotoner `Stopwatch`
  (`metronome_engine.dart:80-139`, Stopwatch `:88`, Taktrechnung
  `computeNextBeatDelayUs` `:66-77`). Diese Zeitachse verlässt das Isolate
  nicht; abgespielt wird der Klick im Main-Isolate beim Empfang der
  Port-Nachricht (`_onBeat`, `:194-225`).
- **Klick-Zeitstempel (beatLog):** `DateTime.now()` im UI-Listener, also erst
  nach Isolate-Nachricht → Notifier-Update → `ref.listen`
  (`practice_session_screen.dart:225-235`; #14 `:411-418`). Wanduhrzeit,
  verspätet um Port- und Frame-Latenz.
- **Onset-Zeitstempel:** main: `DateTime.now()` bei der Fensterverarbeitung —
  faktisch die Chunk-Ankunftszeit (s. Frage 2). #14: **Sample-Uhr** (ms seit
  Sample 0, `onset_detector.dart:69-71,90`), auf die Wanduhr gehoben über
  einen einmaligen Anker: Ankunftszeit des ersten Chunks minus dessen Dauer
  (`mic_analysis_service.dart:24,42-43,86`, Stand #14).

Aufeinander bezogen werden beide Seiten nur implizit darüber, dass beide
`DateTime` verwenden. **Eine Kalibrierung oder Latenz-Korrektur existiert
nicht** (kein Treffer für latency/calibration im Quellcode). Audio-Ausgabe-
latenz (SoLoud-Klick bis Lautsprecher) und Eingabelatenz (Membran bis
Chunk-Ablieferung; im #14-Anker nicht berücksichtigt) stecken unkorrigiert im
gemessenen `deviationMs`. Brief §1.3 setzt hier korrekt an.

## Frage 4 — Session-Datenmodell

**Gespeichert wird pro Session genau fünf Felder — keinerlei Mic-Daten.**

- `PracticeSession` (`lib/data/local/models/practice_session.dart:5-13`):
  `exerciseId`, `durationSeconds`, `achievedBpm`, `rating` (1–3
  Selbstbewertung), `date`. Geschrieben in `saveSession`
  (`lib/features/practice/practice_provider.dart:16-37`).
- Daneben als Lernstand: `RudimentProgress` (BPM-Stand, Spaced-Repetition-
  Felder) und `CleanTempo` (`lib/data/local/models/clean_tempo.dart:10-18`,
  letztes sauberes Tempo je Übung — der einzige persistierte Zustand des
  Trainingsprogramms).
- Die Mic-Auswertung `SessionAnalysis` enthält nur Aggregate (Mittelwert je
  Hand, Jitter, detected/expected —
  `lib/features/coaching/models/session_analysis.dart:3-43`), wird **nur im
  Feedback-Sheet angezeigt** (`practice_session_screen.dart:186-214`) und
  **nirgends gespeichert**. Roh-Onsets leben ausschließlich im Speicher des
  Service und sind nach `dispose()` weg.

→ Es liegen also weder Roh-Onsets **noch** Aggregate vor. Phase 2
(Roh-Logging) baut auf einer grünen Wiese; das Brief-Schema (Kopf + Ereignisse)
kollidiert mit nichts Bestehendem.

## Frage 5 — Tagesstruktur

**Routine (Tagesliste):** `dailyRoutine`
(`lib/features/learning/routine_provider.dart:12-73`) baut die Liste in fester
Reihenfolge: (1) fällige Wiederholungen (`nextReviewDate` ≤ heute, je 6 min,
`:23-37`), (2) aktive, nicht fällige Übungen (je 5 min, `:39-52`),
(3) höchstens eine neue Übung (7 min, `:54-70`); Obergrenze 5 Einträge
(`_maxItems`, `:10`). Kein Zeitbudget, keine Unterscheidung Kern/optional.

**Programm (Tagesblöcke):** Wochenrhythmus über `dayTypeForDayNumber`
(`lib/features/program/program_provider.dart:22-27`): Tag 1–5 üben, Tag 6
leicht, Tag 7 Ruhe. Die Blöcke entstehen in `buildAdaptiveProgramDay`
(`lib/features/program/program_generator.dart:69-147`): Übungstag = Warmup
3 min + Technik 8 min + Tempo-Leiter 4 min (15 min gesamt, `:98-120`);
leichter Tag = Warmup 3 + Technik 5 (8 min, `:121-137`); Ruhetag = leer
(`:138-140`). Alle Dauern hart kodiert.

**Vorhandene Anknüpfungspunkte für die variable Dosis (Phase 4):**

- Die Session-Zieldauer ist im Practice-Screen bereits frei wählbar
  (`_goalSeconds`-Chips, `practice_session_screen.dart:46,323-324`) — die
  „freie Dauer-Wahl" aus Commit `9000190` betrifft dagegen die
  Programm-Laufzeit in Wochen (1–24), nicht die Tagesdosis.
- Der Streak ist bereits anwesenheits- statt pensumbasiert gebaut:
  Ruhetage-bewusst mit Ein-Tages-Gnade
  (`lib/features/stats/stats_provider.dart:11-42,127-130`).
- Einhängestellen: die Item-Auswahl in `dailyRoutine` (Kern/optional-
  Klassifikation), die Blockdauern in `buildAdaptiveProgramDay`, und auf #14
  zusätzlich `lib/features/program/day_completion.dart` (Tag-Abschluss-Logik)
  als natürlicher Ort für „Tag gilt nach dem Kern als abgeschlossen".

## Frage 6 — Kopfhörer-Erkennung

**Nein.** Kein Treffer für headphone/headset/bluetooth/audio_session in
`lib/` — weder auf main noch auf #14 — und kein entsprechendes Paket in
`pubspec.yaml`. Die Kopfhörer-Abfrage für Brief §1.3/§2 (Session-Kopf-Feld
„Kopfhörer ja/nein") muss neu gebaut werden.

---

## Widersprüche & Rückfragen

Gemäß Brief („Antworten, die eine Annahme dieses Briefs widerlegen, führen zu
einer Rückfrage, nicht zu stillem Umdeuten"):

**Widerspruch 1 — „Ausgangsbasis ist PR #14 (gemergt)":** PR #14 ist **nicht
gemergt**, sondern offen als Draft (Branch `worktree-fix+program-ux-mic`);
`origin/main` endet beim Merge von PR #10 (`61c5b3e`). PR #14 enthält dabei
genau die für Etappe 1 zentralen Verbesserungen (OnsetDetector auf Sample-Uhr,
korrektes Noten-beatLog) und hat die Draft-PRs #11 und #13 bereits einge-
mergt (Commits `24cb1fa`, `50aca00`).
**Rückfrage:** Soll PR #14 vor Phase-1-Beginn nach main gemergt werden (damit
wären #11 und #13 miterledigt), oder soll Phase 1 direkt auf dem #14-Branch
aufsetzen? Auf dem heutigen main wäre die Mic-Messung doppelt defekt
(Tick-beatLog + Chunk-Zeitstempel) — Phase 1 auf main aufzusetzen hieße,
Arbeit aus #14 zu wiederholen.

**Widerspruch 2 — §1.2-Abnahme „Vorher: alle folgenden Hände vertauscht":**
Diese Abnahme unterstellt Positionszählung (Onset n ↔ Note n). Tatsächlich
ordnet der Code auf beiden Ständen per zeitlicher Nächste-Nachbar-Suche zu:
Auf #14 bleiben die Hände nach einer Auslassung **korrekt** (die folgenden
Onsets matchen weiter ihre zeitlich nächste Note), auf main ist die Hand wegen
des Tick-Index-Defekts ohnehin beliebig — „vertauscht" ist der
Vorher-Zustand in keinem Fall. Das reale heutige Defizit ist ein anderes:
Auslassungen werden nicht erkannt/gemeldet, überzählige Onsets werden nicht
ausgewiesen, und eine Note kann mehreren Onsets gleichzeitig zugeordnet
werden.
**Rückfrage:** Soll die §1.2-Abnahme entsprechend umformuliert werden (z. B.
„Vorher: Auslassung wird nicht erkannt, Extra-Schlag erhält stillschweigend
eine Hand; Nachher: eine Auslassung erkannt, ein Onset als überzählig
ausgewiesen, 1:1-Zuordnung")? Das Ziel von §1.2 (Alignment mit
Auslassungs-/Einfügungserkennung + Vertrauensmaß) bleibt davon unberührt
sinnvoll.

**Kein Widerspruch, aber offen:** Ob `UNPROCESSED` auf dem S23 Ultra
verfügbar ist, lässt sich aus dem Code nicht belegen (keine Laufzeitprüfung
vorhanden) — der Brief formuliert mit „falls verfügbar" bereits passend;
die Antwort liefert erst der Gerätetest in Phase 1.1.

---

## Repo-Zustand

Stand 06.09.2026, nur Auflistung, nichts aufgeräumt:

- **`origin/main`:** `61c5b3e` — Merge PR #10 (60cm-Redesign), 25.08.2026.
- **Offene Draft-PRs:**
  - **#14** „Fix: 8 Trainingsprogramm-Probleme aus dem Gerätetest (Mic,
    Tempo-Leiter, BPM, Timer)" (`worktree-fix+program-ux-mic`) — die vom Brief
    gemeinte Basis; enthält #11 und #13 per Merge.
  - **#13** „fix: address lesson-UX issues from device testing"
    (`fix/lesson-ux-issues`) — in #14 enthalten (`50aca00`).
  - **#11** „Fix: Snare-Sound + Navigator-Crash-Regression, Pad-Workouts neu
    komponiert" (`worktree-drum-coach-redesign`) — in #14 enthalten
    (`24cb1fa`).
  - **#12** „P1: Desktop-Plattform-Bootstrap" (`worktree-desktop-phase1-spec`)
    — laut Konzept Etappe 2, bleibt liegen.
  - **#2** „Tag-axes migration (Migration Step 2)"
    (`worktree-training-program-stick-control`) — alt (August), Status unklar.
- **Doppelungs-Risiko Standort-Bericht:** PR #14 enthält
  `docs/BERICHT_NEUKONZEPT.md` unter `docs/` (Commit `8591a14`); mit dieser
  Ablage liegt der (inhaltlich identische, per diff geprüfte) Bericht unter
  `docs/concept/`. Nach einem #14-Merge läge er doppelt — beim Merge sollte
  die `docs/`-Kopie entfallen.
- **Unversionierte Reste im Arbeits-Checkout (`docs/`):**
  `BERICHT_NEUKONZEPT_ERGAENZUNG_v1.md` (ältere Fassung, nicht Teil der
  Ablage), `files.zip` (Quell-Zip) sowie die drei Quellkopien der jetzt
  versionierten Konzept-Dateien.
- **Remote-Branches ohne offenen PR:** `feat/notation-bravura-timing` (PR #7
  längst gemergt, Branch übrig), `feature/training-program-stick-control`.
- **Für Phase 1 im Weg:** allein die #14-Basisfrage (Widerspruch 1). Das im
  Brief erwähnte Release-Build-Problem (`isar_flutter_libs`/compileSdk) wurde
  auftragsgemäß nicht untersucht.
