# Bericht Etappe 1 — Phase 2: Roh-Logging jeder Session

**Datum:** 08.09.2026 · **Basis:** main nach Merge von PR #16 (`73a1273`)
· **Brief:** `docs/BRIEF_ETAPPE1_PAD.md` Phase 2

**Stand: Schema angekündigt (dieser Abschnitt, gemäß Arbeitsweise-Regel des
Briefs), Umsetzung folgt darunter.**

---

## Datenschema (Ankündigung vor der Umsetzung)

Grundsatz aus dem Brief: *Nichts wird weggerechnet, was später gebraucht
werden könnte.* Deshalb werden Onset-Zeiten **roh** gespeichert (ohne
Latenzabzug); der bei der Analyse angewandte Kalibrierwert steht separat im
Kopf, sodass jede Korrektur nachträglich reproduzierbar oder revidierbar
ist. Die bestehende `PracticeSession`-Collection (Lernstand/Statistik)
bleibt unverändert; das Roh-Log ist eine **neue, additive** Collection.

### Isar-Collection `SessionLog` (ein Datensatz pro Session)

| Feld | Typ | Inhalt |
|---|---|---|
| `sessionUid` | String | eindeutig, `<epoch-ms>-<exerciseId>` |
| `startedAt` | DateTime | Session-Beginn |
| `exerciseId` | String | Übungs-ID (`Rudiment.id`) |
| `mode` | String | `learn` \| `analysis` — Phase 2 schreibt immer `learn`, Phase 3 übernimmt das Feld |
| `bpm` | int | gewähltes BPM |
| `durationSeconds` | int | Dauer |
| `deviceModel` | String | z. B. `SM-S918B` (Build.MODEL via MethodChannel) |
| `androidVersion` | String | z. B. `14` |
| `audioSource` | String | `unprocessed` \| `voice_recognition` (§1.1) |
| `sampleRate` | int | 16000 |
| `autoGain` / `echoCancel` / `noiseSuppress` | bool | angeforderte Effekt-Zustände |
| `unprocessedSupported` | bool? | Laufzeitprüfung §1.1 |
| `headphones` | String | `none` \| `wired` \| `bluetooth` (neue Erkennung, s. u.) |
| `latencyOffsetMs` | double? | gespeicherter Kalibrierwert zum Session-Zeitpunkt |
| `rating` | int? | Selbstbewertung 1–3 |
| `clickTimesMs` | List\<double\> | geplante Klick-Zeitpunkte, epoch-ms (gemeinsame Zeitachse §1.3) |
| `clickNoteIndices` | List\<int\> | Notenposition je Klick (Sticking-Bezug) |
| `events` | List\<OnsetEvent\> | eingebettet, s. u. |

### Eingebettetes Objekt `OnsetEvent` (ein Eintrag pro erkanntem Onset)

| Feld | Typ | Inhalt |
|---|---|---|
| `timeMs` | double | Onset-Zeit **roh**, epoch-ms, sample-genau auf der gemeinsamen Zeitachse (chunk-lokal gemappt, §1.3) — ohne Latenzabzug |
| `peakLevel` | double | Spitzenpegel (roher Weg §1.1) |
| `notePosition` | int? | zugeordnete Notenposition; `null` = überzählig |
| `hand` | String? | `R` \| `L` — nur falls zugeordnet **und** Durchlauf über der §1.2-Schwelle |
| `deviationMs` | double? | Alignment-Abweichung (mit angewandter Latenzkorrektur — abgeleiteter Wert, Rohzeit bleibt daneben erhalten) |

### JSONL-Export (eine Datei pro Session, zusätzlich Tages-Export)

Zeile 1 = Session-Kopf (`{"type":"session", …}` inkl. `clicks`), danach eine
Zeile pro Onset (`{"type":"onset", …}`). Export über den Android
Teilen-Dialog (share_plus); in den Einstellungen zusätzlich ein
Tages-Export (alle Sessions des Tages in einer Datei, Zeilen einfach
aneinandergereiht).

### Neue Kopfhörer-Erkennung

§0 ergab: keine vorhanden. Neu über den bestehenden MethodChannel
`drum_coach/audio`: `AudioManager.getDevices(GET_DEVICES_OUTPUTS)` →
`wired` (WIRED_HEADSET/WIRED_HEADPHONES/USB_HEADSET/USB_DEVICE), `bluetooth`
(A2DP/BLE), sonst `none`. Wird pro Session im Kopf festgehalten (und steht
Phase 3+ für die im P1-Bericht notierte Kopfhörer-Kalibrierung zur
Verfügung).

---

## Umsetzung

- **Ereignisliste:** `analyzeHits` liefert jetzt pro erkanntem Onset ein
  Roh-Ereignis (`OnsetEventData`: rohe epoch-ms-Zeit ohne Latenzabzug,
  Spitzenpegel, Notenposition oder überzählig, Hand nur über der
  §1.2-Schwelle, Abweichung) —
  `lib/features/coaching/models/session_analysis.dart`,
  `mic_analysis_service.dart`; Tests in `test/coaching/mic_analysis_test.dart`.
- **Modell + Persistenz:** Neue Isar-Collection `SessionLog` mit
  eingebetteten `OnsetEvent`s (`lib/data/local/models/session_log.dart`),
  registriert in `isar_service.dart`; Aufbau aus Analyse + Kontext als pure
  Funktion `buildSessionLog` (`session_log_service.dart`, Tests in
  `test/data/session_log_builder_test.dart`). **Jede** Session wird geloggt;
  ohne Mikrofon mit `audioSource: "off"` und leeren Ereignis-/Klick-Listen
  (kleine Schema-Ergänzung gegenüber der Ankündigung).
- **JSONL:** `sessionLogToJsonl` (`session_log_codec.dart`, Tests in
  `test/data/session_log_codec_test.dart`); Tages-Export = aneinander-
  gereihte Session-Blöcke.
- **Export:** Feedback-Sheet-Button „Session exportieren (JSONL)" für die
  frische Session; *Einstellungen → Session-Logs von heute exportieren* für
  den Tages-Export — beides über den Android-Teilen-Dialog (`share_plus`).
- **Kopfhörer-Erkennung + Gerät:** Neue MethodChannel-Methoden
  `headphonesType` (`none`/`wired`/`bluetooth` via
  `AudioManager.getDevices`) und `deviceInfo` (Build.MODEL,
  Android-Version) in `MainActivity.kt`; Dart-Wrapper mit Channel-Mock-Tests
  (`recording_setup.dart`, `recording_setup_test.dart`).
- **Tests:** Gesamtsuite **239/239 grün**, 10 neue in Phase 2.

### Beispiel (Format-Illustration aus dem Unit-Test; echte Datei folgt unten)

```jsonl
{"type":"session","sessionUid":"1757354000000-single_stroke_roll","startedAt":"2026-09-08T18:30:00.000Z","exerciseId":"single_stroke_roll","mode":"learn","bpm":74,"durationSeconds":17,"deviceModel":"SM-S918B","androidVersion":"14","audioSource":"voice_recognition","sampleRate":16000,"autoGain":false,"echoCancel":false,"noiseSuppress":false,"unprocessedSupported":false,"headphones":"wired","latencyOffsetMs":69.0,"rating":2,"clickTimesMs":[1000.5,1500.5],"clickNoteIndices":[0,1]}
{"type":"onset","timeMs":1074.2,"peakLevel":0.31,"notePosition":0,"hand":"R","deviationMs":4.7}
{"type":"onset","timeMs":1290.0,"peakLevel":0.12,"notePosition":null,"hand":null,"deviationMs":null}
```

## Abnahme

**Brief:** Eine echte Übungssession exportieren, auf dem Laptop öffnen,
alle Felder befüllt. Beispieldatei in den Bericht.

**Gerätetest-Anleitung:**
1. Übung mit Mikrofon-Analyse und Kopfhörern spielen (~20 Schläge),
   beenden, bewerten.
2. Im Feedback-Sheet „Session exportieren (JSONL)" → im Teilen-Dialog einen
   Weg zum Laptop wählen (oder Datei speichern; alternativ hole ich sie per
   Kabel aus dem App-Cache).
3. Datei am Laptop öffnen: Kopfzeile vollständig (inkl. `headphones:
   "wired"`, `latencyOffsetMs: 69`, Gerät), eine Onset-Zeile pro Schlag mit
   Notenposition/Hand/Abweichung, Klick-Zeiten befüllt.

| Prüfpunkt | Ergebnis |
|---|---|
| Alle Kopf-Felder befüllt | ☐ |
| Onset-Zeilen mit Zuordnung/Hand/Abweichung | ☐ |
| Klick-Zeiten + Notenindizes vorhanden | ☐ |
| Beispieldatei im Bericht verlinkt/eingefügt | ☐ |
