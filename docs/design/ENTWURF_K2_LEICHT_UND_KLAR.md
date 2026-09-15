# K2 Entwürfe: „leicht, luftig, modern, klar" (15.09.2026)

**Status:** Entwurf zur Sichtung. Kein Arbeitsauftrag, bis du eine Richtung
freigibst (Brief Neukonzept §3: „Entwürfe zuerst").
**Bezug:** `docs/BRIEF_NEUKONZEPT_OPTIK_INHALTE.md` (PR #20), K1 Sprachpass (PR #21).

## Die Leinwand

https://claude.ai/artifact/9jEsaZ4VMqEa9xYXhTHZPh

Sechs Handy-Bilder (390 × 844) auf einer Leinwand, dazu Notizzettel:

| Screen | Richtung A (dunkel, oben) | Richtung B (hell, unten) |
|---|---|---|
| Today (ersetzt Dashboard) | Main | TodayLight |
| Practice (Übungs-Screen) | Practice | PracticeLight |
| Result (Feedback-Blatt) | Result | ResultLight |

Beide Richtungen haben denselben Aufbau. Unterschied ist nur die Grundfläche:
A bleibt bei den Hausfarben (Schwarz #101010, Orange #FF6A2B, Schriften
Space Grotesk + IBM Plex Mono; das Notenpapier bleibt hell). B nimmt den
Papier-Ton #FAF8F3 als Grundfläche der ganzen App.

## Was die Entwürfe zeigen

**Today.** Ganz oben die zwei Türen aus dem Brief: „Continue the path" mit
dem nächsten Schritt (Übung, Stufe, Tempo, Dauer) und einem einzigen
Knopf, darunter „Practice freely" mit dem Weg in die Bibliothek. Erst
danach, klein: Streak und Tagesminuten. Der alte Kartenstapel (Programm,
Collection, Technique, Pad-Workouts, Routine, letzte Session, Metronom)
entfällt. Über dem Pfad-Schritt ein Platzhalter für eine Illustration.

**Practice.** Notenblatt und Zählwerk (1 2 3 4, der aktive Schlag in
Orange) füllen den Screen und sind aus 60 cm lesbar. Die Kopfzeile ist
entschlackt: Name, Stufe, ein Chip für Modus und Mikro. Unten kompakt:
Tempo-Leiter, BPM mit ±, ein Stop-Knopf mit Restzeit. Sound, Dauer und
Feinschritte wandern hinter „⋯". Gezeigt ist der laufende Zustand.

**Result.** Das Urteils-Banner bleibt oben. Darunter drei Kernwerte statt
neun Zeilen: Hits (Treffer von erwartet), Timing (Abstand zum Klick +
Streuung), Evenness (Gleichmäßigkeit, mit Hand-Werten). Das Selbst-Rating
steht direkt darunter im selben Blatt statt als eigenes Fenster davor.
Alles Weitere hinter „Measurement details".

## Was ich angenommen habe

1. UI-Texte auf Englisch (K1-Entscheidung), Notizen für dich auf Deutsch.
2. Hausschriften und Orange bleiben; nur Flächen, Abstände und Hierarchie
   ändern sich.
3. Drei Tabs: Today · Library · Progress (statt Dashboard, Routine,
   Lessons, Stats). „Routine" geht im Pfad-Schritt auf.
4. Rating und Ergebnis werden ein Blatt (heute: Rating-Sheet, dann Dialog,
   dann Feedback-Sheet).
5. Kernwerte: Hits, Timing, Evenness. Die Trefferquote in Prozent wird
   heute berechnet, aber nirgends angezeigt.
6. Illustrationen nur als gestrichelte Platzhalter (ComfyUI-Hausstil noch
   offen; GPU-Box war aus).
7. Alle Zahlen sind Beispielwerte.
8. Weiße Schrift auf Orange (Start, Stop, Done) hat nur etwa 3:1 Kontrast.
   Das ist die bisherige Haus-Konvention; die Alternative wäre dunkle
   Schrift auf Orange. Sag Bescheid, wenn dir das wichtig ist.

## Deine Entscheidungen

1. Richtung A (dunkel) oder B (hell)?
2. Rating ins Ergebnis-Blatt zusammenlegen: ja / nein?
3. Drei Tabs Today · Library · Progress: ja / nein?
4. Kernwerte Hits / Timing / Evenness: die richtigen drei?
5. Zählwerk „1 2 3 4" oder pulsierender Kreis: was liest sich aus 60 cm
   besser?

## Wie es weitergeht

Nach deiner Wahl baue ich K2 in dieser Reihenfolge um: Today, Practice,
Result. Abnahme wie im Brief: Screenshots vom Gerät, dein Urteil
„leicht / luftig / klar".

## Nachbesserung nach eigener Sichtung (15.09.)

Notation im Übungs-Screen vergrößert (füllte das Blatt nur halb), das
Ergebnis-Blatt wächst jetzt von unten statt ein Loch in der Mitte zu lassen,
Zweittext-Kontrast angehoben, alle Tipp-Ziele mindestens 44 px, Rahmen von
Knöpfen und Chips sichtbarer, Einheiten einheitlich (zum Beispiel „+3 ms“).

## Dateien

`docs/design/k2-entwuerfe/gen.py` erzeugt die sechs Artboards
(`*.dc.html`) und das Leinwand-Layout (`canvas.json`). Änderungen an
Farben oder Aufbau gehören in `gen.py`, nicht in die erzeugten Dateien.
