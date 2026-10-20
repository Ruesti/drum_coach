# Bericht: Geführte Übungen — Plan 1 „Klang-Fundament" (Hörprobe)

Stand 18.10.2026, Branch `spec-gefuehrte-uebungen`. Plan 1 ist gebaut: der
„Ablauf-Spieler" (spielt eine ganze geführte Übung Takt für Takt ab, mit
Einzähler, Crash, Groove, Ansage-Stimme, Countdown, Variationen und
Schluss-Crash). Eine richtige Liste mit Übungen kommt erst in Plan 2. Zum
Anhören gibt es jetzt eine **versteckte Hörprobe-Seite** mit zwei
Demo-Übungen.

## Wo die Seite ist

App öffnen → **Settings** (Einstellungen) → ganz nach unten scrollen → dort
steht klein **„Version 1.0.0+1"**. Diese Zeile **lange gedrückt halten** →
die Seite „Guided demo" geht auf. (Absichtlich kein sichtbarer Menüpunkt.)

Auf der Seite:

- **Kit demo / Pad demo** — welche Übung (nur wählbar, solange nichts läuft).
  - Kit: Rock-Achtel (Hi-Hat Achtel, Snare 2 + 4, Bassdrum 1 + 3), 100 BPM.
    Variation 1: Bassdrum zusätzlich auf „3-und". Variation 2: dazu ein leiser
    Snare-Ghost auf „2-e". Variation 3: dazu offene Hi-Hat auf „4-und".
  - Pad: Achtel R L, 90 BPM. Variation 1: Akzent auf jeder Zählzeit.
    Variation 2: Doppelschläge R R L L. Variation 3: Paradiddle R L R R L R L L.
  - Ablauf je Übung: Einzähler → Crash → Groove 12 Takte → Variation 24 Takte →
    Groove → Variation → Groove → Variation → Groove → Schluss-Crash.
    Dauer: Kit etwa 4:53 min, Pad etwa 5:25 min.
- **Start / Pause / Stop**, Tempo **− / +** (je 4 BPM). Am Desktop auch per
  Tastatur: Leertaste = Start/Pause, ↑ ↓ oder + − = Tempo, Esc = Stop.
- Schalter **Teacher** (Lehrer-Stimme an/aus) und **Play along** (an: die App
  spielt den Groove mit; aus: nur ein Viertel-Klick).
- Darunter die Statuszeile, z. B. `Section 3 of 9 · Variation 1 · bar 5 · beat 2`
  (Abschnitt, Takt im Abschnitt, Schlag), der Erklärtext der laufenden bzw.
  kommenden Variation, ein Zeitbalken mit „verstrichen / gesamt". Fehler des
  Spielers erscheinen oben als rote Zeile.

Alles auf Englisch (Bildschirm und Stimme).

## Was du bitte testest (Spec §4, Punkte 2–4)

1. **Einmal ganz durchhören (ca. 5 min).** Ablauf stimmt: Crash → Groove →
   Erklärung → Countdown („three, two, one, go") → Variation → Groove … →
   Schluss-Crash. **Nie ein Wechsel ohne Ansage + Countdown.** Klingt jeder
   Taktübergang sauber (kein Knacksen, kein Holpern)?
2. **Tempo mitten drin hoch und runter** (mehrmals + und −). Erwartung: kein
   Neustart, kein Aussetzer; das neue Tempo greift ab dem nächsten Takt. Die
   Übung läuft an derselben Stelle weiter. (Genau: im Puffer liegen immer
   etwa 0,5 s fertiger Ton. Drückst du erst in der letzten halben Sekunde
   eines Takts, ist der nächste schon fertig — dann greift es einen Takt
   später.)
3. **Pause und weiter**, auch kurz vor dem Schluss-Crash. Erwartung: Ton
   stoppt sofort und kommt erst mit „Resume" wieder; der Schluss-Crash
   klingt ganz aus und wird nicht abgeschnitten.
4. **Teacher aus** (vor dem Start oder mittendrin). Erwartung: gleicher Ablauf,
   aber ohne Stimme; der Countdown ist dann ein **betonter Klick** auf den
   Schlägen 2–4. Hinweis: das Banner mit Countdown-Zahlen kommt erst mit dem
   richtigen Übungs-Screen (Plan 2); hier steht nur der Erklärtext.
   Wird Teacher mittendrin wieder **an**geschaltet, greift das erst ab dem
   nächsten Abschnitt.
5. **Stimme klar über dem Groove?** Versteht man jeden Satz, auch bei der
   Kit-Übung mit Bassdrum und Hi-Hat?
6. **Stimme cori oder ljspeech?** In der App ist **cori** (britisch) eingebaut.
   Zum Vergleich liegen beide Stimmen als Hörbeispiele auf dem NUC in
   `~/gefuehrt-stimmen/` (je ein Satz + „three, two, one, go"). Wenn dir
   ljspeech (amerikanisch, etwas kürzere Wörter) lieber ist: sag Bescheid,
   dann rendere ich die Clips neu.
7. Optional: **Play along aus** — nur noch Viertel-Klick, Stimme und
   Countdown bleiben.

## Installation auf dem S23

Das APK liegt auf dem NUC unter `~/gefuehrt-plan1.apk` (Debug-Build). Wenn der
Laptop online ist und das S23 per USB dranhängt, auf dem NUC:

```bash
scp ~/gefuehrt-plan1.apk laptop:~/agent-test-checkouts/
ssh laptop adb -s RFCW220PB7W install -r ~/agent-test-checkouts/gefuehrt-plan1.apk
```

Am Ende muss „Success" stehen. Hinweis: alle drum_coach-APKs haben bisher die
Versionsnummer 1; ein Neu-Installieren drüber klappt deshalb.

## Desktop (Linux) auf dem Laptop

Das Desktop-Programm muss **auf dem Laptop** gebaut werden (der NUC hat eine
neuere Systembibliothek, ein dort gebautes Programm startet auf dem Laptop
nicht). Dafür gibt es einen **eigenen Checkout** `drum_coach-guided` — der
Etappe-2-Checkout (`drum_coach-etappe2-phase-b`) bleibt unberührt.

Beim ersten Mal (legt den Checkout an):

```bash
ssh laptop
git clone git@github.com:Ruesti/drum_coach.git ~/agent-test-checkouts/drum_coach-guided
```

Danach jedes Mal:

```bash
ssh laptop
cd ~/agent-test-checkouts/drum_coach-guided
git fetch && git checkout spec-gefuehrte-uebungen && git pull --ff-only
~/development/flutter/bin/flutter build linux --release
rsync -a --delete build/linux/x64/release/bundle/ ~/drum-coach-guided/
~/drum-coach-guided/drum_coach
```

Dann wie am Handy: Settings → Versionszeile lange drücken (am Desktop: Maus
gedrückt halten). Voraussetzung: der Branch ist gepusht (ist er zum
Zeitpunkt dieses Berichts noch nicht — das macht der Gesamt-Abschluss).

## Stand der Prüfung durch Claude (NUC, Emulator)

Siehe Abschnitt „Emulator" unten — dort steht, was ohne dich schon geprüft
ist (Seite öffnet, Lauf startet, Position läuft, Renderzeit je Takt).
Nicht geprüft (Laptop war offline): Installation auf dem S23, Linux-Bundle.
Hören kann nur du — der Emulator hat keinen Ton.

## Emulator

Geprüft am 18.10. auf dem Android-Emulator des NUC (Debug-APK, ohne Ton):

- Settings → Versionszeile lange drücken → Seite „Guided demo" geht auf.
  Bilder: `~/gefuehrt-plan1-emulator.png` (Seite), 
  `~/gefuehrt-plan1-emulator-running.png` (10 s nach Start),
  `~/gefuehrt-plan1-emulator-settings.png` (Versionszeile).
- Start → Statuszeile läuft (nach 10 s „Section 2 of 9 · Groove · bar 4"),
  Zeitbalken läuft, keine rote Fehlerzeile, kein Fehler im Geräte-Log.
- Tempo mitten drin 100 → 108: greift ab dem nächsten Takt, Lauf geht weiter.
  Teacher mittendrin aus: kein Fehler.
- **Rechenzeit je Takt** (Takt erzeugen, im Hintergrund): 4–53 ms, meist
  5–40 ms; ein Takt dauert bei 100 BPM 2400 ms. Vorlauf im Puffer stets
  etwa 2,2–2,4 s. Also sehr viel Luft.

## Befunde

### Erster Test, 20.10.2026 (Uli am S23 und Linux-Laptop)

1. **S23: „Start" zeigte sofort „Resume", kein Ton.** Ferngesteuert am selben
   Gerät um 18:01–18:04 nicht nachstellbar: Kit- und Pad-Demo spielen,
   Stop → Start, App im Hintergrund und zurück — alles läuft (Lautsprecher).
   Ursache offen; Rückfrage an Uli, was beim Fehlversuch anders war
   (Bluetooth-Kopfhörer? Bildschirm gesperrt?).
2. **Linux: Kick und Snare nicht zeitgleich.** Ursache gefunden: SoLouds
   MP3-Dekodierung (miniaudio) lässt die MP3-Kodierverzögerung drin (1105
   Samples = 25 ms Stille vorn) → Snare und Crash 25 ms zu spät.
   **Behoben** (cd3a794): Snare/Crash als WAV, in Dart gelesen. Betrifft
   auch die normalen Übungen (MetronomeEngine liest weiter snare.mp3) —
   eigene Korrektur, noch offen.
3. **Tempowechsel greift erst nach ein paar Sekunden.** Vorlauf von 1,2 s auf
   0,5 s verkürzt (S23 rechnet einen Takt in ≤ 60 ms). Das neue Tempo gilt
   weiter ab dem nächsten Takt.
4. **Klingt sehr computergeneriert.** Erwartet: Kick/Hi-Hat sind synthetisch,
   die Stimme ist Piper. Echte Schlagzeug-Samples und Hintergrundband sind
   ein eigener Schritt (Plan 2 / Band-Spec).
