# Bericht: Blattform — eine Übung ist ein Blatt aus nummerierten Zeilen

Datum 01.10.2026 · Branch `blattform` (von `main` 2d4cd3a) · Spec
`docs/superpowers/specs/2026-09-30-blattform-design.md` · Plan
`docs/superpowers/plans/2026-09-30-blattform.md`.

## 1. Was gebaut wurde

- **Modell.** Eine Übung kann Zeilen tragen (`ExerciseLine`: Noten, Wiederholung,
  Überschrift, Zählhilfe). `Rudiment.sheet` liefert immer mindestens eine
  Zeile; die 127 alten Übungen laufen unverändert als Ein-Zeilen-Blätter.
  `withSticking` reicht die gespielte Einheit als gewöhnliche Übung weiter.
- **Einheit.** `SheetPlan` (rein): eine Zeile oder das ganze Blatt (jede
  Zeile einmal) als flache Notenliste mit Rückweg für den Cursor.
- **Zählhilfe.** `countLabelsFor`: „1 e + a" binär, „1 + a" ternär, nichts
  auf Pausen und Zwischenpositionen.
- **Notation.** `SheetStaffWidget`: ein Maler je Zeile, alle Reihen gleich
  hoch (`SheetGeometry`, Bänder für Überschrift und Zählhilfe), Nummern-
  Kästchen, `|:` `:|`, Schlussstrich, Überschrift, Zählsilben, inaktive Zeile
  gedämpft. Buchstaben, Zahlen und Silben in der Label-Schrift der App.
  Golden `test/goldens/sheet_staff_three_lines.png` (mit Bravura geladen).
- **Notenfenster.** `SheetWindow` (Nachtrag Uli 30.09.): bis zu vier Reihen,
  gespielt wird immer in der obersten, am Reihenende rutscht der Inhalt in
  180 ms eine Reihe hoch, Loop-Anfang und Zeilenwechsel springen ohne
  Animation, im Blatt-Modus folgt nach der letzten Reihe die erste.
- **Übungs-Screen.** Spielt die Einheit (Zeile im Kreis oder Blatt in Folge);
  Zeilenleiste `‹ Line 3 / 11 ›` + `Line | Sheet`; Tipp auf eine sichtbare
  Zeile wählt sie; Wechsel im Lauf baut den Loop neu und beginnt auf der Eins;
  `?line=`/`?mode=`, Position je Übung gemerkt, Pausen-Schnappschuss mit
  Zeile und Modus; ⋯-Blatt mit „Sticking letters" und „Count hints".
- **Lektion nur auf Abruf.** Info-Seite: PATTERN (nacktes Muster, nur bei
  Blättern mit Zeilen), THE SHEET (Tipp auf eine Zeile startet sie), LESSON
  (Why it matters / How to play it / Practice tips / Song examples). Der
  Übungs-Screen zeigt nur Noten.
- **Daten.** `SessionLog.sheetLine/sheetMode` (Isar-Code neu generiert),
  JSONL-Export erweitert; Library-Kachel nennt Zeilen und Takte.
- **Probestück.** `single_paradiddle` trägt ein Blatt mit 10 Zeilen à 2 Takte
  (Zeilen 1–3 mit Zählhilfe) und einer 8-Takt-Challenge ohne Wiederholung
  (28 Takte). Platzhalter bis zum Katalog-Schritt.

## 2. Entscheidungen des Auftraggebers (30.09.)

1. Blattform der Vorbild-PDFs („sowas will ich").
2. Vorgehen: Muster-Blätter → Blattform in der App → Katalog in Blättern.
3. **Kommando zurück** zur Zweiteilung Lektion/Zellen: Lektion nur auf Abruf,
   als Übung nur Noten, jede Übung so abwechslungsreich und groovy wie möglich.
4. Nachtrag: vier Notenreihen, oben wird gespielt, am Reihenende rutscht es.
5. Spec und Plan freigegeben, Bau nativ.

## 3. Abweichungen vom Plan

- Integritätsregel „jede Zeile ganze Takte" gilt nur für geschriebene
  Zeilen: 19 Basis-Rudiments sind kürzer als ein Takt (schon immer, der Loop
  kachelt sie); die 64-Takt-Grenze gilt für alle Blätter.
- Reihenhöhe wächst auch um ein Titelband, sobald eine Zeile eine
  Überschrift hat (sonst wäre die Überschrift mit den Akzenten der ersten
  Note kollidiert); `sheetRepeatSystemPad` = 20 statt 12, damit `|:` nicht
  in die erste Note ragt.
- Der Seed-Katalog ist jetzt eine normale Liste (`final`), weil das
  Probestück mit der DSL gebaut wird.
- Messung-mit-Einheit: kein Widget-Test (der Mikro-Dienst ist im Screen
  nicht ersetzbar); Sicherung über Code-Review und Gerätetest.
- Das Notationstest-Setup lädt Bravura per `FontLoader`, sonst zeigt das
  Golden Kästchen statt Noten.

## 4. Tests

Neu: `sheet_plan_test` (5), `count_labels_test` (6), `sheet_geometry_test`
(5), `sheet_window_test` (8), `settings_sheet_test` (3),
`lesson_detail_sheet_test` (3), `lessons_screen_meta_test` (1); erweitert:
`rudiment_model_test` (+3), `etude_dsl_test` (+1), `etudes_integrity_test`
(+2), `notation_staff_test` (+6 inkl. Golden), `session_log_builder_test`
(+1), `practice_session_screen_test` (+10). Ganze Suite auf der GPU-Box
(01.10.): **445 Tests grün**. Analyzer: nur die 12 bekannten Warnungen.

## 5. Sichtprüfung

Emulator-Screens (Debug-Build, S23-Profil 1080×2340): Probestück vor dem
Start (Fenster mit drei Reihen — so viele passen auf 780 dp — Zeile 1 oben,
Zeilen 2/3 gedämpft, Zeilenleiste), Zeile 2 im Lauf, Blatt-Modus im Lauf
(Fenster hochgerutscht, „Sheet · 28 bars"), Optionen mit SHEET, Info-Seite
(PATTERN · THE SHEET · LESSON), alte Ein-Zeilen-Übung (Kästchen 1, `|: :|`,
keine Leiste), Library-Kachel mit Zeilen/Takten; das Gedächtnis je Übung
zeigte sich nebenbei (Paradiddle öffnete im zuletzt gewählten Blatt-Modus).

https://claude.ai/artifact/NZVEgAHrXywaxgx3v2APeK

## 6. Stand

Wird nach Suite, Review und Sichtprüfung ergänzt.

## 7. Offen (Spec §12)

- Automatisches Weiterschalten nach n Durchläufen, lückenloser Zeilenwechsel
  (Vorab-Render je Zeile).
- Zwei Durchläufe je Zeile im Blatt-Modus; Bewertung je Zeile.
- Tempo-Stufen auf der Info-Seite; Dynamikzeichen, Volten, Da Capo.
- Katalog Schritt 3 nach der Regel „so abwechslungsreich und groovy wie
  möglich" (6–10 Zeilen à 2 Takte + Challenge); Probestück ersetzen.

## 8. Gerätetest S23 (ausstehend)

Zeile im Kreis mit Backing; ‹ › im Lauf; Blatt-Modus bei 60 BPM — Zeit bis
zum ersten Klick (Grenze 1 s) und bei 140 BPM; Fenster rutscht an jeder
Reihengrenze, Challenge über vier Reihen, Umlauf springt; vier Reihen zwischen
Kopfzeile und Zeilenleiste; Mikro-Messung auf einer Zwei-Takt-Zeile; Info-
Seite; Alt-Übung unverändert.
