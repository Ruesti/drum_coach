# Nachtrag Etappe 2 — B.4c: Set-Inhalt Füße, Double Bass, mehr Fills und Grooves

**Datum:** 16.10.2026 · **Anlass:** Uli, 16.10.: „Am wichtigsten ist mir, dass bis ich
heimkomme schön viele Übungen fürs Set gemacht werden. Inkl. Fills, Grooves, Übungen
für Foot/Bass, Double Bass." · **Bezug:** `docs/BRIEF_ETAPPE2_SET.md` Phase B (B.1,
B.2, B.4); Plan Teil 1 `docs/superpowers/plans/2026-10-15-etappe2-phase-b1-set-mehrstimmig.md`
(16 Set-Blätter: 6 Grooves, Open Hi-hat, 8 Fills mit Time, Rund ums Set).

**Ziel:** Bis zur Heimkehr (ca. 24.10.) elf bis zwölf weitere Set-Blätter — Fuß-Kontrolle,
Double Bass, Hi-Hat-Fuß und Ostinati, lineare Fills und Grooves, Fills in Double-Bass-
Läufe — in derselben Form wie Teil 1 (8 Zeilen + Challenge, kuratiert in `tool/katalog`,
Kurationsseite, Goldens, Emulator-Sichtprüfung). Dazu die eine Notenbild-Erweiterung,
die Double Bass braucht: **Fußbuchstaben R/L**.

---

## §1 Fußseite im Modell und Notenbild

- Eine Fußnote **darf** eine Seite tragen: rechter oder linker Fuß. Modell: `StrokeBeat.hand`
  bleibt `Hand?`; auf einer Fußstimme bedeutet `hand` die Fußseite. DSL: `foot(NoteValue v,
  {…, Hand? side})`. Notenschrift: Flag `r`/`l` nur auf `K`/`P`-Tokens (`K16r`, `K16l`);
  ohne Flag bleibt die Seite offen (wie bisher, `null`).
- Messung (Teil 2) ignoriert die Seite: ein Kick ist eine MIDI-Note, zwei Pedale sind
  nicht unterscheidbar.
- Notenbild: Ein Blatt, auf dem irgendeine Fußnote eine Seite trägt, bekommt eine
  **zweite Buchstabenzeile** unter den Fuß-Hälsen. Kit-Reihe mit Fußbuchstaben:
  Reihenhöhe **146** (statt 132), Titel 96, Fußbuchstaben 114, Handbuchstaben 130,
  Zählsilben 146 (+ Zählband 14). Fußbuchstaben folgen demselben Schalter „Sticking
  letters" wie die Handbuchstaben. Blätter ohne Fußseiten zeichnen unverändert (132).
- Kurationsseite: ohne Fußbuchstaben (die Seiten wechseln bei Double Bass ohnehin
  R L R L; der Hinweis steht in der Legende: „Fußseiten R/L nur in der App").
- Integritätstest: eine Zeile, die Fußseiten mischt (teils gesetzt, teils offen), ist
  erlaubt; `Limb.doubleBass` ⇒ mindestens eine Fußnote mit Seite im Blatt.

## §2 Die Blätter

Alle `kit=True`, `requiredSensor: midi`, `backing=None`, `new_seed=True`; Form wie Teil 1
(Grooves/Übungen 8 × 2 Takte + Challenge 8; Fills 8 × 4 Takte + Challenge 8). Zeile 1 ist
immer die Grundform, Zeilen 2–8 steigern oder variieren, Challenge = vier Zeilen
hintereinander. Lektion vier Abschnitte wie bisher. Regel (Uli, 30.09.): so
abwechslungsreich und groovy wie möglich.

### Satz `feet` (B.4c, Füße) — 7 Blätter

| Id | Name | Stufe · Grid · Limbs | Inhalt |
|---|---|---|---|
| `feet_kick_control` | Kick Control | beginner · eighth · feet | Hände HH8 + SN24, Kick: Viertel 1/3 → 1/3 + „3 +" → Doppel 1 1+ → „+" allein (2+/4+) → Sechzehntel-Doppel („1 e", „3 a") → Vier auf dem Boden → Lücken (nur 2 und 4 +) → Mischung |
| `feet_kick_sixteenths` | Kick Sixteenths | intermediate · sixteenth · feet | Hände HH8 + SN24 (Zeilen 5–8 HH16): Kick-Kombinationen je Zählzeit: 1e, 1a, 1+a, e+, ea, 1e+a, +a, a-1 (Auftakt über den Taktstrich) |
| `feet_double_bass_eighths` | Double Bass Eighths | intermediate · eighth · doubleBass | Kick R L R L Achtel durchgehend; Hände HH Viertel + SN24; Varianten: nur Takt 1 Teppich/Takt 2 Viertel, Pause auf 4, Hände auf Ride, Snare auf 3, Ausbruch zwei Zählzeiten, Akzente mit der Snare, Hände Achtel unisono |
| `feet_double_bass_sixteenths` | Double Bass Sixteenths | advanced · sixteenth · doubleBass | Sechzehntel-Teppich R L; Hände HH Viertel + SN24 (Metal); halbe Takte Teppich, Ein-Zählzeit-Bursts, Snare auf 3 (Half-time), Hand-Fuß-Unisono auf der 1, Crash-Wechsel, Teppich mit Lücke auf „a" |
| `feet_double_bass_triplets` | Double Bass Triplets | advanced · triplet · doubleBass | Triolen-Teppich R L R L …; Shuffle-Hände; Bonham-Dreier (R L K als Triole über Hände und Kick), Sextolen-Bursts, Triolen nur auf 2 und 4, Fuß-Shuffle (K · K) |
| `feet_hihat_foot` | Hi-hat Foot | intermediate · eighth · feet | HP 2/4 unter Ride-Achteln + SN24 + Kick 1/3; HP auf allen Vieren; HP auf „+" (Chick-Offbeat); Splash-Pedal (HP + HO zusammen); HP 2/4 mit Kick-Figuren aus Kick Control; Ride-Glocke mit HP; HP als einziger Puls unter Snare-Figuren |
| `feet_ostinatos` | Foot Ostinatos | advanced · sixteenth · allFour | Samba-Fuß (K 1, „1 a"? → K auf 1 und „a", HP auf 2/4 … klassisch `K8. K16 ` je Zählzeit mit HP 2/4) unter Hand-Figuren; Jazz-Feathering (Kick Viertel leise) + HP 2/4 + Ride + Comping; Bossa-Fuß (K 1, 2+, 3, 4+); je Familie 2–3 Zeilen |

### Satz `set_more` (B.4c, mehr Fills und Grooves) — 4 bis 5 Blätter

| Id | Name | Stufe · Grid · Limbs | Inhalt |
|---|---|---|---|
| `set_fill_linear` | Linear Fill (Kit) | intermediate · sixteenth · allFour | drei Takte Rock-16tel-Groove, ein Takt linearer Fill (Hände und Kick nie zugleich): R L K, R L K K, R L R K, R K L K über Snare/Toms + Kick; Crash auf der Eins |
| `set_fill_double_bass` | Double Bass Fill (Kit) | advanced · sixteenth · doubleBass | drei Takte Groove, ein Takt Fill: zwei Zählzeiten Hände (Snare → Toms), zwei Zählzeiten Füße R L Sechzehntel; Varianten 1+3, 3+1, Sextolen-Füße, Triolen |
| `groove_linear` | Linear Groove | intermediate · sixteenth · allFour | lineare Grooves (keine zwei Gliedmaßen zugleich): HH/SN/BD-Sechzehntel-Abfolgen, Ghosts, offene Hat als Abschluss |
| `groove_kick_sixteenths` | Sixteenth Kick Groove | intermediate · sixteenth · allFour | Rock-16tel-Grooves mit Kick auf „e"/„a", Ghost-Snares, Hat-Akzente; Half-time-Variante |
| `groove_halftime_shuffle` (optional, wenn Zeit) | Half-time Shuffle | advanced · triplet · allFour | Purdie/Porcaro-Shuffle: Ghost-Snares auf den Triolen, Backbeat auf 3, Kick 1 + „let" von 2 |

Reihenfolge der Umsetzung: `feet` zuerst (Ulis Priorität), dann `set_more`.

## §3 Abnahme (ohne Set, im Emulator)

- `python3 feet.py` / `python3 set_more.py` ok; Kurationsseiten mit Fußbuchstaben;
  Integritätstests grün (Fußseiten, Limbs, Form); Goldens: Pattern von
  `feet_double_bass_sixteenths` und `feet_kick_control`, ganzes Blatt
  `feet_double_bass_eighths` (Reihenhöhe 146, zwei Buchstabenzeilen).
- Emulator-Screenshots: Bibliothek mit Filter Limbs = Double bass, Info-Seite „Double
  Bass Sixteenths", Übungs-Screen „Kick Control" laufend.
- APK `~/drum-coach-set-b1c.apk`.

## §4 Nicht in diesem Nachtrag

Messung pro Stimme (B.3, Teil 2); 6/8 und andere Taktarten; Song-Ausschnitte;
Heel-Toe-Technik als eigene Notation (Fußbuchstaben genügen); App-eigene Set-Klänge.
