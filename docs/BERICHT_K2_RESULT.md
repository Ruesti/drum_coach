# Bericht K2 Schritt 3 — Ergebnis-Blatt (28.09.2026)

Spec: `docs/superpowers/specs/2026-09-27-k2-result-design.md`,
Plan: `docs/superpowers/plans/2026-09-27-k2-result.md`, Branch `k2-result`
(auf `main` nach dem Merge von Practice, PR #25).

## Was gebaut wurde

Nach der Übung erscheint jetzt **ein** helles Blatt statt der bisherigen zwei
dunklen (erst Bewertung, dann Feedback). Es folgt dem K2-Entwurf vom 15.09.:
Rating oben, Kernwerte in Klartext, Messdetails zum Aufklappen.

- **Ablauf:** Stop → Finish (oder Zeitablauf) hält Metronom, Marker und Mikro
  an, rechnet die Analyse und öffnet das Blatt. Es lässt sich weder
  wegwischen noch mit der Zurück-Taste schließen (`PopScope`); der einzige
  Weg zurück ist „Done".
- **Kopf:** „SESSION COMPLETE", Name der Übung, Zeile „84 BPM · 8:00 ·
  analysis" (bzw. „learn").
- **Banner** (nur mit Mikro-Analyse): grün bei sauberem Lauf („Clean run —
  hand analysis below."), sonst gelb-orange mit dem bisherigen Wortlaut
  (Aussetzer mit Zeitstempel, „Too unsteady …", „Too many dropped notes …",
  „Recording too quiet …").
- **„HOW DID IT FEEL?"** — drei Chips Struggled / OK / Solid mit der
  Tempo-Folge darunter („same BPM", „+2 BPM", „+5 BPM"). Der **erste Tipp
  speichert** die Sitzung, ein zweiter Tipp ändert nichts mehr. „Done" wird
  frei, sobald Speichern, Snapshot-Löschen und (bei der Leiter) der
  Clean-Dialog durch sind. Schlägt das Speichern fehl, gibt das Blatt den
  Chip wieder frei und sagt es („Couldn't save the session — tap a rating to
  try again.").
- **Nach dem Rating** erscheinen darunter, sobald sie da sind: die Leiter-
  Meldung („Clean tempo now 88 BPM."), das Coach-Feedback (Karte erst ab dem
  Rating, sofort als „lädt", nur mit API-Schlüssel) und der Export-Link
  „Export session (JSONL)". Log und Coach laufen nach dem Freigeben weiter;
  wer vorher Done tippt, verliert nichts (Log ist gespeichert, Coach-Antwort
  wird verworfen).
- **Drei Kernwerte** in Klartext, je eine fette Aussage plus eine graue
  Messzeile (Tabelle unten). Ohne Mikro-Analyse steht stattdessen ruhig
  „No mic analysis this time".
- **„Measurement details"** zugeklappt: die alten Messzeilen (Timing vs
  click, Matched / missed / extra, R hand, L hand, Jitter, Levels …).
- **Gelöscht:** `_RatingSheet`, `_FeedbackSheet`, `_AnalysisSummary`,
  `_VerdictBanner` im Screen und die dunkle `CoachFeedbackCard`-Einbindung;
  der Screen ist um rund 250 Zeilen kürzer.

## Wortlaut und Schwellen (`core_values.dart`)

Millisekunden gerundet, positiv = hinter dem Klick.

| Wert | Quelle | Regel | Aussage |
|---|---|---|---|
| Treffer | `alignment` | keine Fehler | You hit every note |
| | | N verpasst | You miss N note(s) |
| | | nur Extra-Schläge | You add N extra stroke(s) |
| | nur `unassigned` | expected − played | dieselben Sätze, Messzeile „played of expected played" |
| Timing | Median m | \|m\| ≤ 5 ms | You're right on the click |
| | | 5 < \|m\| ≤ 15 ms | You rush a little / You drag a little |
| | | \|m\| > 15 ms | You rush / You drag |
| Hände | Analyse-Modus, Hand-Werte frei | \|rechts − links\| ≤ 5 ms | Your hands are even |
| | | rechts später | Your right hand is late |
| | | links später | Your left hand is late |
| Gleichmäßigkeit | sonst, Streuung e | e ≤ 10 ms | Your strokes are even |
| | | 10 < e ≤ 20 ms | Your strokes are slightly uneven |
| | | e > 20 ms | Your strokes are uneven |

Messzeilen: „30 of 32 hit · 94 %", „3 ms ahead of the click · ±11 ms spread",
„right +2 ms · left +5 ms · ±9 ms jitter", „±9 ms between strokes".
Bei zu leiser Aufnahme bleibt die Liste leer (das Banner sagt es).

## Tests

- `core_values_test.dart` (13): jede Schwelle von beiden Seiten und mit
  beiden Vorzeichen (Timing ±5/±6, ±15/±16; Hände 5/6; Gleichmäßigkeit
  10/11, 20/21), Einzahl/Mehrzahl, Rückfall auf `unassigned`, leere Liste
  bei zu leisem Signal.
- `result_sheet_test.dart` (10): Kopf/Banner/Kernwerte, Done erst nach dem
  Rating und nur ein Speichern, Done gesperrt solange das Speichern läuft,
  Fehlerpfad gibt den Chip frei, Coach-Karte erst nach dem Rating, zu leises
  Signal (Banner, keine Kernwerte, keine No-mic-Zeile), No-mic-Zeile,
  Details auf/zu, Export nur mit Log, Leiter-Meldung kommt später an.
- `result_sheet_golden_test.dart` (1): Vorschau mit Beispielwerten,
  `test/goldens/result_sheet_preview.png` (1080×2760, absichtlich höher als
  ein Handy, damit das ganze Blatt ohne Scrollen sichtbar ist).
- `practice_session_screen_test.dart`: Finish und Zeitablauf öffnen das
  Blatt, die Zurück-Taste schließt es nicht, ein Rating speichert genau
  einmal und löscht einen echten Snapshot (Fake-Notifier statt Isar).
- Ganze Suite auf der GPU-Box: **338 Tests grün** (vorher 305), Analyzer nur
  die 12 bekannten `experimental_member_use`-Warnungen.

## Sichtprüfung

- Emulator (AVD s23, ohne Mikro): Fahrt Today → Start → Practice → Start →
  Stop → Finish → Blatt („No mic analysis this time") → „OK" → Done aktiv →
  Done. Screenshots `~/k2-practice-screens/emu/r1_sheet.png`,
  `r2_rated.png`, Seite `result-emulator.html` daneben.
- Mikro-Zustand (Banner, Kernwerte, Leiter-Meldung) nur über die
  Golden-Vorschau, weil der Emulator keine Aufnahme liefert.

## Entscheidungen beim Bauen (Ledger)

- Golden-Vorschau 1080×2760 statt Handy-Höhe: das Blatt liegt im Golden ohne
  Scroll-Hülle; in der App scrollt es im Bottom-Sheet.
- Speichern im Widget-Test über einen Fake-Notifier statt Isar; der Zähler
  gehört dem Test, weil der Provider `autoDispose` ist und die Instanz nach
  dem Aufruf stirbt.
- Symbole erscheinen im Golden als Kästchen (Icon-Schrift wird in Tests nicht
  geladen) — bekannt, kein Fehler.

## Review-Durchgang (frischer Reviewer, 28.09.)

Drei Important, sieben Minor, drei Nit — alle Important und die meisten
Minor gefixt:

- **Zurück-Taste schloss das Blatt ohne Speichern** → `PopScope(canPop:
  false)`; zusätzlich poppt der Screen nach dem Blatt nur noch, wenn die
  Sitzung gespeichert ist.
- **Done war schon aktiv, während das Speichern lief** (schneller Done-Tipp
  übersprang den Leiter-Dialog und traf entsorgte Notifier) → `onRate` ist
  jetzt `Future`, das Blatt sperrt Done bis es zurückkommt; im Screen nach
  jedem `await` ein `mounted`-Check; Log und Coach laufen entkoppelt.
- **Coach-Karte zeigte vor dem Rating einen Fehler** → Karte erst ab dem
  Rating, Ladezustand wird vor dem ersten `await` gesetzt.
- Speicherfehler wurden verschluckt → Fehlerpfad im Blatt (siehe oben).
- Analyse-Absturz hätte das Speichern blockiert → try/catch, Blatt ohne
  Analyse.
- Doppelter Finish-Tipp konnte zwei Blätter öffnen → `_finishing`-Sperre.
- Snapshot-Test bewies nichts → legt jetzt einen echten Snapshot an.
- Schwellen-Tests nur einseitig → beidseitig ergänzt (siehe Tests).
- Rating-Chips: Mindest- statt Festhöhe (große Schrift, schmale Geräte),
  `Semantics(button, selected)`.
- Leiter-Dialog war dunkel unter hellem Theme (Titel unlesbar, älter als der
  Branch) → hell wie das Blatt.
- Gesperrter Done-Knopf: grauer Grund statt blassem Orange mit weißer Schrift.
- Spec-Nit: „|m| ≤ 0,5" → „gerundet 0", passend zum Code und zur Anzeige.

Bewusst nicht geändert: Details-Zeile hat die Material-Mindesthöhe 56 statt
der 48 aus der Spec (Standard-`ExpansionTile`); `hasMic` schließt
`signalTooWeak` ein (Banner „too quiet" braucht den Zweig).

## Offen

- Banner-Wortlaut („not solid yet") ist noch der alte, technische; ein
  Klartext-Pass steht aus.
- Dynamik (Anschlagstärke) als vierter Kernwert, sobald die Messung stabil
  genug ist.
- Gerätetest am S23 mit echtem Mikro (Banner, Kernwerte, Leiter-Dialog).
- Reste aus dem Practice-Review (Layout-Sprung bei Finish-Zeile, ±-Knöpfe
  deaktiviert zeichnen, Seed-Muster auf ganze Takte).
