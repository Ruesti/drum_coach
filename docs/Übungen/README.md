# Übungen (lokale Referenz, nicht versioniert)

Dieser Ordner ist für lokal abgelegte Lehr-PDFs gedacht (Sticking-Übungen,
Warm-Ups, Solo-Etüden etc.), die als Inspiration für neue Übungen in der App
dienen. Die PDFs selbst sind **absichtlich nicht eingecheckt** (siehe
`.gitignore`), da ihr Copyright-Status gemischt ist — mindestens eine bisher
hier abgelegte Datei war explizit kommerziell lizenziert (© OnlineDrummer.com).

## Vorgehen

Übungen aus PDFs in diesem Ordner werden **nicht abgetippt/kopiert**, sondern
als pädagogisches Vorbild genutzt: gleiche Übungs-Konzepte (Notenwert-Mix,
Sticking-Stil, Schwierigkeitsprogression), aber frei neu komponiert im
DSL-Format (`lib/features/lessons/data/etude_dsl.dart`).

Die "Pad-Workouts"-Sammlung (`ExerciseCollection.padWorkouts`) in
`lib/features/lessons/data/etudes/{sticking_pattern,warmup,beginner_count,
accent_workout,pad_solo}_etudes.dart` (30 Übungen, August 2026) wurde so aus
sechs vom Nutzer bereitgestellten PDFs abgeleitet:

- Sticking-Übungen (Handsätze) — manuholmer.de
- Einspielübung mit Snare / Übungspad — manuholmer.de
- Erste Übungen für die Snaredrum — Benjamin Pflug, laermmanufaktur.de
- Kleines Snaresolo — Benjamin Pflug, laermmanufaktur.de
- Urlaubs-/Ferien-Drum-Workout — laermmanufaktur.de
- The Pad – Exercise 1 — © OnlineDrummer.com (Nate Brown) — **nur stilistisch
  als "16tel-Akzent-Gruppierungs"-Konzept berücksichtigt, nicht direkt
  verwendet**, da explizit kommerziell copyright-geschützt.
