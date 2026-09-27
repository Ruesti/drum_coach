# K2 Schritt 3 „Result" — Design-Spec (27.09.2026)

Nach der Übung gibt es ein einziges, helles Ergebnis-Blatt: Urteils-Banner,
direkt darunter das Selbst-Rating, dann drei Kernwerte in Klartext mit der
Messzahl klein darunter, alles Weitere hinter „Measurement details".
Grundlage: Entwurf `docs/design/ENTWURF_K2_LEICHT_UND_KLAR.md` (Branch
k2-design-entwuerfe, Draft-PR #22), Mockup `Result.dc.html` (hell, Rating
oben), Brief §3 und §9 (PR #20). Entscheidungen des Auftraggebers vom 15.09.:
Result hell, Rating oben im selben Blatt, Kernwerte in Klartext. Vom 27.09.:
Wortlaut und Schwellen wie in §4, Practice-PR #25 vorher gemergt.

## 1. Ziel und Nicht-Ziele

**Ziel.** Nach dem Üben sieht der Drummer in einem Blick: Wie lief es
(Banner), wie fühlte es sich an (Rating), was sagt die Messung in drei
Sätzen. Zahlen nur klein darunter, Rohwerte nur auf Wunsch.

**Nicht-Ziele.**
- Keine Änderung an Messung, Alignment, Latenz, `analysisAnnouncement`
  (Banner-Logik bleibt wörtlich), `saveSession`, `buildSessionLog`, Export.
- Der Leiter-Dialog „Clean & relaxed?" (`_askCleanPass`) bleibt, wie er ist.
- Die KI-Coach-Karte bleibt optional (nur mit API-Schlüssel), unverändert.
- Kein Umbau von Today/Progress.

## 2. Ablauf

Heute: Rating-Blatt → speichern → Leiter-Dialog → Analyse → Feedback-Blatt.
Neu:

1. **Sitzung endet** (Finish oder Zeitablauf): Metronom, Ticker, Mikro
   stoppen wie heute. Analyse berechnen (wie heute, nur vor dem Blatt).
2. **Ein Blatt** `ResultSheet` öffnet, hell, nicht wegwischbar
   (`isDismissible: false`, `enableDrag: false`), `isScrollControlled`.
3. **Rating-Tipp** (Struggled / OK / Solid): sofort `saveSession` (wie heute),
   Snapshot löschen, Session-Log bauen und speichern (braucht das Rating),
   bei Leiter der Dialog „Clean & relaxed?" (Ergebniszeile erscheint dann im
   Blatt), KI-Feedback anstoßen (falls Schlüssel). Der gewählte Chip bleibt
   markiert; ein zweiter Tipp ändert nichts mehr (einmal gespeichert).
4. **Done** ist bis zum Rating deaktiviert; danach schließt es Blatt und
   Screen (`context.pop()` wie heute).

## 3. Aufbau des Blatts (hell, Papier-Ton, `drumCoachTheme` + `AppColors`)

Von oben nach unten, Innenabstand 20, scrollbar:

1. Griff (36×4).
2. Eyebrow „SESSION COMPLETE" (Mono 11, Versalien, `textMuted`), Titel =
   Übungsname (`title`), Zeile „84 BPM · 8:00 · analysis" bzw. „learn"
   (`textMuted`, 13).
3. **Urteils-Banner** (`VerdictBanner`, wie heute, grün/orange), nur wenn
   Mikro-Daten (`analysis.hasData` oder `signalTooWeak`) und
   `analysisAnnouncement` etwas liefert.
4. **Rating**: Eyebrow „HOW DID IT FEEL?", darunter drei Chips in einer Reihe
   (je 56 hoch, flexibel): „Struggled / same BPM", „OK / +2 BPM",
   „Solid / +5 BPM". Gewählt = Akzent-Füllung und -Rahmen; die Farben rot,
   gelb, grün der alten Knöpfe entfallen (ruhiger, das Blatt bewertet nicht
   das Gefühl).
5. **Leiter-Ergebniszeile** (Treppen-Symbol + Text) nach dem Dialog, falls
   Leiter.
6. **Kernwerte**: drei Zeilen, getrennt durch Haarlinien, je Satz (17,
   `textPrimary`) und Messzeile (13, `textMuted`). Nur mit Mikro-Daten und
   nicht bei `signalTooWeak`. Ohne Mikro-Daten stattdessen eine ruhige Zeile
   „No mic analysis this time" (`textMuted`).
7. **KI-Coach-Karte** (`CoachFeedbackCard`) wie heute, nur mit Schlüssel.
8. **„Measurement details"**: aufklappbare Zeile (48 hoch, Haarlinien
   oben/unten, Chevron). Darin die bisherigen Messzeilen (Timing vs click,
   Evenness, Dynamics spread, Strokes, Matched/missed/extra, Latency
   correction, R/L hand, Consistency, Dynamics R/L, Learn-Hinweis) und die
   Rohzeilen (Levels, Deviation, Recording). Nur mit Mikro-Daten.
9. **Done** (orange, 56, bis zum Rating deaktiviert).
10. „Export session (JSONL)" als kleiner Textknopf, nur wenn Session-Log.

## 4. Kernwerte in Klartext

Reine Funktion `coreValues(SessionAnalysis a, {required bool analysisMode})`
→ `List<CoreValue>` (`head`, `sub`), Datei
`lib/features/practice/core_values.dart`. Millisekunden ganzzahlig gerundet,
Vorzeichen: positiv = hinter dem Klick (Konvention der Messung).

**Treffer** (aus `alignment`, sonst `unassigned`):
- `alignment` da: `missed == 0 && extra == 0` → „You hit every note";
  `missed > 0` → „You miss N note" / „You miss N notes"; `missed == 0 &&
  extra > 0` → „You add N extra stroke(s)". Messzeile „H of E hit · P %"
  (P = H/E gerundet), bei extra > 0 zusätzlich „ · X extra".
- nur `unassigned`: `d = expected − played`: d > 0 → „You miss d notes",
  d < 0 → „You add |d| extra strokes", 0 → „You hit every note"; Messzeile
  „played of expected played".

**Timing** (aus `unassigned.timingMedianMs`, m):
- |m| ≤ 5 → „You're right on the click"
- 5 < |m| ≤ 15 → m < 0 „You rush a little", m > 0 „You drag a little"
- |m| > 15 → „You rush" / „You drag"
- Messzeile „|m| ms ahead of the click · ±S ms spread" bzw. „behind the
  click"; bei |m| ≤ 0,5 „on the click · ±S ms spread".

**Hände / Gleichmäßigkeit:**
- `analysisMode && timing != null` (Hand-Werte freigegeben): `diff = right −
  left`; |diff| ≤ 5 → „Your hands are even"; diff > 5 → „Your right hand is
  late"; diff < −5 → „Your left hand is late". Messzeile „right +2 ms · left
  +5 ms · ±J ms jitter" (Vorzeichen je Hand, J = `timing.jitterMs`).
- sonst (Lern-Modus oder Gate zu) aus `unassigned.intervalSpreadMs` (e):
  e ≤ 10 → „Your strokes are even", 10 < e ≤ 20 → „Your strokes are slightly
  uneven", e > 20 → „Your strokes are uneven". Messzeile „±e ms between
  strokes".

Fehlt `unassigned` ganz (Analyse ohne Rohwerte) → nur die Treffer-Zeile, wenn
`alignment` da; sonst leere Liste (dann zeigt das Blatt die No-mic-Zeile).
`signalTooWeak` → leere Liste (das Banner sagt „too quiet").

## 5. Dateien

- Neu `lib/features/practice/core_values.dart`: `CoreValue`, `coreValues`.
- Neu `lib/features/practice/widgets/result_sheet.dart`: `ResultSheet`
  (StatefulWidget, öffentlich, damit testbar), `VerdictBanner` (aus dem
  Screen hierher verschoben, öffentlich), `_RatingChip`, `_CoreValueRow`,
  `_DetailsSection` (die alten `_AnalysisSummary`-Zeilen + Rohwerte).
  Parameter: `rudimentName`, `bpm`, `durationSeconds`, `analysisMode`,
  `analysis` (nullable), `announcement` (nullable), `ladderResult`
  (nullable, ändert sich nach dem Dialog → der Screen reicht es über einen
  `ValueListenable<String?>` hinein, damit das offene Blatt es anzeigt),
  `sessionLog` (nullable, ebenfalls Listenable, entsteht nach dem Rating),
  `coachFeedback`/`coachLoading` (Listenables), `onRate(int)`, `onDone`,
  `onExport`.
- `lib/features/practice/practice_session_screen.dart`: `_showRatingSheet`
  wird `_finishSession` (Ablauf §2), `_saveAndShowFeedback` wird
  `_onRated(int)`; `_RatingSheet`, `_RatingButton`, `_FeedbackSheet`,
  `_AnalysisSummary`, `_Row`, `_VerdictBanner` entfallen; Aufrufer
  (`Finish`-Knopf, Ticker-Zeitablauf) rufen `_finishSession`.
- Tests: `test/features/practice/core_values_test.dart`,
  `test/features/practice/result_sheet_test.dart`; Screen-Test anpassen
  („How did it feel?" bleibt sichtbar, Done erst nach Rating).
- Vorschau fürs Auge: ein Widget-Test rendert das Blatt mit Beispielwerten
  als Golden-Bild (`test/goldens/result_sheet_preview.png`, erzeugt mit
  `flutter test --update-goldens`), damit der Look ohne Mikro am Emulator
  beurteilt werden kann. Am Emulator selbst zeigt das Blatt die No-mic-Fassung.
- `docs/BERICHT_K2_RESULT.md`, CLAUDE.md-Notiz.

## 6. Tests

- `coreValues`: jede Satzvariante und jede Schwelle (5/15 ms, 5 ms Hände,
  10/20 ms Gleichmäßigkeit), Rundung, Singular/Plural, Lern-Modus ohne
  Hand-Werte, ohne `alignment`, `signalTooWeak` → leer, ohne `unassigned`.
- `ResultSheet` (Handy-Fläche 1080×2340): Banner sichtbar wenn gegeben;
  drei Chips, Tipp ruft `onRate(2)` und markiert den Chip; Done vor dem
  Rating deaktiviert, danach aktiv und ruft `onDone`; Kernwerte-Sätze
  sichtbar; ohne Analyse „No mic analysis this time"; Details zu, nach Tipp
  offen mit „Timing vs click"; Export nur mit Log; kein Überlauf.
- Screen: Finish → „How did it feel?" sichtbar; Rating-Tipp → Snapshot
  gelöscht (`SettingsService.practiceSnapshotFor` null) und Done aktiv.

## 7. Abnahme

Emulator: Practice → Start → Stop → Finish → Blatt (No-mic-Fassung), Rating
tippen, Done. Dazu das Golden-Bild mit Beispielwerten. Urteil des
Auftraggebers „leicht / luftig / klar".

## 8. Offen gelassen

- Wortlaut des Banners bleibt der heutige (Clean run / Fell off at … / Too
  unsteady …); Feinschliff, wenn der Rest steht.
- Dynamik („too soft / uneven volume") als vierter Kernwert: erst, wenn die
  Roh-Pegel am Gerät verlässlich sind (Brief Phase 2 offen).
