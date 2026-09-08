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

*(folgt nach der Implementierung)*

## Abnahme

**Brief:** Eine echte Übungssession exportieren, auf dem Laptop öffnen,
alle Felder befüllt. Beispieldatei in den Bericht.

*(offen — Gerätetest)*
