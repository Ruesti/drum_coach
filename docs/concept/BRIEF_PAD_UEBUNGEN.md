# Brief: Pad-Übungen — was es geben soll und was die Engine dafür kann

**Datum:** 15.09.2026, Fassung 2 (nach Klarstellung am Abend) · **Status:**
Konzept-Entwurf zur Sichtung, kein Arbeitsauftrag. Rückfragen in §8. ·
**Bezug:** `BERICHT_NEUKONZEPT.md` (§2 Punkt 2 „Übungsqualität", §3c
„Content-Strategie", Fragen 7 und 8), `BERICHT_NEUKONZEPT_ERGAENZUNG.md`
(Befund G, §8 Song-Zentrale, §9), `BRIEF_SONG_UEBUNGEN.md`,
`../BRIEF_NEUKONZEPT_OPTIK_INHALTE.md` (§4 K3, §5 K4, §9 Entscheidungen
15.09.). Ist-Stand des Codes: Branch `k1-english-pass`, 15.09.

---

## §1 Entscheidungen des Auftraggebers (15.09.)

1. **Pad heißt einstimmig.** Auf dem Pad gibt es nur Übungen mit einer
   Stimme, einem Klang. Grooves mit Snare, Hi-Hat, Kick und Toms gehören
   ans Drum-Set (Etappe 2), nicht aufs Pad.
2. **Songs und Songstellen kommen aus ausgewerteten Songs.** Die eigene
   Pipeline (Demucs plus ADTOF auf der GPU-Box, validiert an „Battery")
   liefert die Drum-Notation; daraus werden Übungsstellen. Das ist
   Set-Inhalt, keine Pad-Übung.
3. **Drei Pad-Übungstypen:** Rudiment-Drills, Fill-Stickings, kleine Stücke.
   („Grooves am Pad" aus Fassung 1 entfällt, siehe Punkt 1.)
4. **Motivation aus vier Quellen:** musikalischer Zusammenhang, Mitspielen zu
   Musik, klares Ziel mit Messung, Abwechslung und Steigerung.
5. **Play-Along: Backing-Loop im Zieltempo** statt nur Klick
   (Bericht-Frage 8 beantwortet).
6. **Die 86 generierten Übungen: alle weg**, der Katalog wird neu kuratiert
   (Bericht-Frage 7, zweiter Teil).
7. **Grundwortschatz aus Standardwerken und Zielsongs** (Brief Neukonzept §9).
   Am Pad davon die Fill-Stickings; die Grooves gehören ans Set.
8. **Reihenfolge: Optik (K2), dann Engine, dann Katalog.**
9. **Wer komponiert:** Claude nach Vorbildern, der Auftraggeber kuratiert
   am Pad.

## §2 Ist-Stand in vier Sätzen

Die App hat 41 Rudiments und 86 Étüden. Eine Übung ist eine einstimmige
Notenliste: R/L je Note, Akzent, Ghost, Flam/Drag-Vorschläge, Pausen,
gemischte Notenwerte, Triolen und Sextolen, beliebig viele Takte in x/4;
Bravura-Notation, Wiedergabe auf einem 24-Tick-Raster, Messung von Treffer,
Auslassung, Extraschlag, Timing, Streuung, Hand-Werten und Einbrüchen.
Einstimmig passt also zum Pad-Grundsatz; das Modell ist richtig, der Inhalt
nicht. Der Katalog ist eine Technik-Bibliothek: 56 der 86 Étüden sind
Akzent-Permutationen, Punktierung kommt nie vor, Pausen fast nie,
Technik-Hinweise fehlen in allen Étüden. Das erklärt den Eindruck
„Permutationen statt Musik".

## §3 Die drei Pad-Übungstypen — Bauplan

### 3.1 Rudiment-Drills (Technik und Assessment)

- **Was:** die wichtigsten Rudiments, etwa zwölf: Single und Double Stroke
  Roll, Single und Double Paradiddle, Paradiddle-diddle, Flam, Flam Accent,
  Flam Tap, Drag, Five und Seven Stroke Roll, Six Stroke Roll, Swiss Army
  Triplet. Jedes mit Kurzanleitung (was ist es, wofür braucht man es, worauf
  achten), Zieltempo und Tempo-Leiter.
- **Rolle:** messbarer Technik-Kern und Lieferant der Assessment-Aufgaben
  (Brief Neukonzept §4).
- **Varianten:** Akzentverschiebung, Verdichtung und ähnliche Drills dürfen
  weiter generiert werden, erscheinen aber als Variante innerhalb des
  Rudiments, nicht als eigener Katalog-Eintrag (§5, Punkt 4).
- **Was er hört:** Klick; Loop wahlweise.

### 3.2 Fill-Stickings (Grundwortschatz am Pad)

- **Was:** Ein-Takt-Fills als Handsatz: Sechzehntel-Singles, Paradiddle-Fill,
  Sextolen-Fill, Flam-Fill, Triolen-Fill, Sechser-Gruppen. Einstimmig; am Set
  wird derselbe Handsatz später auf Snare und Toms verteilt.
- **Form:** 3 Takte Time-Muster plus 1 Takt Fill, geloopt als
  Vier-Takt-Phrase. Das Time-Muster ist einstimmig (zum Beispiel Achtel R L
  oder ein Rudiment als Time); die Band kommt aus dem Loop. Das übt Ausstieg
  und Einstieg, und genau das ist die Schwierigkeit (Befund G: „Fill setzen,
  wieder einsteigen").
- **Was er hört:** Backing-Loop, im Fill-Takt läuft der Puls weiter, damit
  die Eins danach sitzt.
- **Messung:** Onsets wie heute. Erfolg heißt: Fill getroffen und die Eins
  danach sauber. Der Einstieg ist als eigener Wert messbar (Timing der ersten
  Note nach dem Fill).
- **Herkunft:** Standardrepertoire plus die Fills, die in den ausgewerteten
  Songs vorkommen (Handsatz-Auszug, siehe §6).
- **Anzahl:** 8.

### 3.3 Kleine Stücke (Étüden im echten Sinn)

- **Was:** 8 bis 16 Takte, einstimmig, mit Form (A A B A oder Intro, Time,
  Fill, Ende), Dynamik-Verlauf, Akzent-Melodie, Pausen, Punktierung. Ziel
  ist, das Stück am Stück, sauber und im Zieltempo durchzuspielen.
- **Vorbilder:** Wilcoxon-Solos, Material aus Stick Control und Syncopation,
  Pad-Solo-Hefte. Komponiert nach Vorbild, nie kopiert (Regel aus
  `../Übungen/README.md`).
- **Was er hört:** Klick oder leichter Loop, wahlweise. Stücke funktionieren
  auch ohne Backing.
- **Messung:** wie heute. Die Einbruch-Erkennung aus Etappe 1 ist hier am
  wertvollsten, weil es um das Durchhalten der Form geht.
- **Anzahl:** 6 bis 10, gestaffelt nach Pfad-Stufe. Ein Stück je Stufe als
  Abschlussstück.

### 3.4 Ausblick Set (nicht Teil der Pad-Etappe)

Grooves mit Snare, Hi-Hat, Kick und Toms sowie Songstellen aus den
ausgewerteten Songs sind Set-Inhalt (Etappe 2 und 3, `BRIEF_SONG_UEBUNGEN.md`).
Sie brauchen mehrstimmige Notation und den Import der Transkription
(Quantisierung, Tempo-Erkennung, Ausschnitt wählen). Das Pad liefert dafür
die Hände: ein Set-Groove hat seinen Handsatz, ein Set-Fill sein Sticking,
beides ist am Pad als einstimmige Übung vorbereitet.

## §4 Was jede Übung mitbringt (Karteikarte)

Name (sprechend, Englisch) · ein Satz „warum" · ein Hör-Hinweis („listen
for …") · Typ und Rubrik · Pfad-Stufe · Tempo min und Ziel · Länge in Takten
· Backing-Loop (Stil, Feel) · Herkunft (Vorbild oder Song) · drei
Technik-Hinweise (Bewegung, typischer Fehler, Übeplan) wie im alten
Rudiment-Katalog · Abruf-Stufe nach Befund G · Illustration (K2). Die
heutigen Étüden haben davon nur Name und einen Beschreibungssatz.

## §5 Was die Engine dafür braucht (Lücken, nach Wichtigkeit)

1. **Backing-Loop neben dem Pattern.** Heute ersetzt das Pattern die
   Klickspur; es läuft kein Puls mit. Nötig ist eine zweite Spur mit eigenem
   Pegel. Weil die Pad-Stimme einstimmig ist, kann der Loop die ganze Band
   außer der gespielten Stimme tragen (Vorschlag: Kick, Bass, Hi-Hat).
   Umsetzung: Loop aus Einzelsamples im 24-Tick-Raster rendern, wie heute
   der Klick-Loop. Dann passt er in jedes Tempo ohne Audio-Stretching.
2. **Dynamikstufen.** Heute drei Pegel (Ghost, normal, Akzent). Nötig: fünf
   Stufen oder ein freier Wert je Note, plus Verlauf über Takte (Crescendo).
   Notation: Dynamikzeichen und Gabeln.
3. **Form-Zeichen und Text.** Wiederholungszeichen mit Zählung, Volten,
   Da Capo, Text über dem System (Tempoangabe, „Fill", Zählhilfe). Spart
   Ausschreiben und macht Stücke lesbar.
4. **Varianten in einer Übung.** Eine Übung mit Stufen a/b/c statt drei
   Einträge. Für 3.1 und 3.2.
5. **Messung.** Akzent-Soll gegen die Pegel prüfen; Vorschlagsnoten (Flam,
   Drag) nicht als eigene Treffer zählen (bekannter Fehler, verzerrt heute
   Hand-Werte); Jitter-Sperre feel-bewusst machen (Shuffle und Swing sind ein
   Soll-Raster, keine Unruhe); Fill-Einstieg als eigener Wert.
6. **Klang.** Snare-Sample mit echten Pegelstufen (Velocity-Layer) statt
   reinem Lautstärke-Faktor.
7. **Mehrstimmigkeit und Transkriptions-Import** erst in der Set-Etappe
   (Ergänzung §9, technische Fragen 6 und 7).

## §6 Herkunft und Recht

- **Komponiert, nicht kopiert.** Vorbilder (Stick Control, Syncopation,
  Wilcoxon, die PDFs in `docs/Übungen/`) liefern Prinzipien, keine Zeilen.
- **Ausgewertete Songs:** die Transkription eines eigenen Songs ist
  Eigennutzung. Ein Fill-Sticking, das aus einem Song abgeleitet ist, ist
  eine Übung über einen Fill-Typ; der Songname als Herkunft ist in Ordnung.
  Vor einer Veröffentlichung der App ist das erneut zu prüfen (Ergänzung §9,
  technische Frage 11).
- **Backing-Loops:** eigene Samples oder synthetisch, keine Song-Ausschnitte.

## §7 Vorgehen (beschlossene Reihenfolge: Optik, Engine, Katalog)

1. **K2 Optik** zuerst (läuft, Entscheidungen 15.09. liegen vor).
2. **Engine für Pad-Inhalte** (§5, Punkte 1, 2, 5): Loop-Spur,
   Dynamikstufen, Mess-Korrekturen. Eigene Phase mit Gerätetest.
3. **Katalog neu**, je Rubrik ein Draft-PR: 12 Rudiments als Karteikarten,
   8 Fill-Stickings, 6 Stücke. Claude komponiert nach Vorbildern, der
   Auftraggeber kuratiert am Pad: macht Spaß, klingt nach Musik, ist messbar.
   Für die Fills vorher: welche Fills kommen in den ausgewerteten Songs vor
   (Auszug aus der Transkription).
4. **Die alten 86 entfernen**, sobald der neue Kern spielbar ist. Nicht
   vorher, sonst ist die App leer.
5. **Set-Etappe** danach: Grooves, Songstellen, mehrstimmige Notation,
   Transkriptions-Import.

Einordnung: Schritte 2 bis 4 sind der Inhalt von K3 (Rudiments, Stufen) und
K4 (Bibliothek) aus dem Brief Neukonzept.

## §8 Rückfragen an den Auftraggeber

1. **Backing-Loop-Besetzung:** Kick, Bass und Hi-Hat als Band um die
   einstimmige Pad-Stimme — oder schlanker (nur Kick als Puls)?
2. **Größen am Pad:** 12 Rudiments, 8 Fill-Stickings, 6 Stücke — passt das?
3. **Welche Songs zuerst auswerten?** Nicht dringend; bestimmt später die
   Fill-Auswahl und die Set-Etappe. „Battery" liegt schon transkribiert vor.

Beantwortet am 15.09. abends: Herkunft der Songs (ausgewertete Songs),
Pad einstimmig, Reihenfolge Optik → Engine → Katalog, Komposition nach
Vorbildern durch Claude.
