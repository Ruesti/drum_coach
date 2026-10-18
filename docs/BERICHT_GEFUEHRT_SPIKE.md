# Bericht: Spike „Geführte Übungen" — Stream + Ansage-Stimme (Plan 1, Task 0)

Stand 18.10.2026. Spike-Code liegt auf Branch `spike/gefuehrt-stream`
(wird nie gemergt). Hier nur das Ergebnis und was Uli noch anhören muss.

## Worum ging es

Die geführte Übung braucht einen „Ablauf-Spieler": Schlagzeug wird **Takt für
Takt** erzeugt und an SoLoud (unsere Audio-Bibliothek) **nachgeschoben**, statt
wie heute eine fertige Schleife abzuspielen. Damit gehen Tempowechsel an
jeder Taktgrenze, Übungen länger als 64 Takte und eine Ansage-Stimme, die in
den Klang hineingemischt wird.

Getestet:

- SoLoud-„Stream" (`setBufferStream`: 44,1 kHz, mono, Float32, `preserved`,
  0,1 s Puffer-Schwelle), Takte werden mit **1 Takt Vorlauf** angehängt.
- Groove 4/4: Hi-Hat in Achteln, Bassdrum auf 1, 3 und „3-und", Snare
  (echtes Snare-Sample) auf 2 und 4.
- Ab Takt 4 alle 8 Takte der Ansage-Satz, 3 Takte später „three, two, one"
  auf Schlag 2–4 und „go" auf der nächsten Eins.
- Automatischer Lauf über **150 Takte** mit 9 Tempowechseln
  (100 → 110 → 120 → 90 → 140 → 160 → 70 → 100 → 180 → 100 BPM).
- Anzeige: gerenderter Takt, `getPosition` (die Abspiel-Uhr von SoLoud), daraus
  berechneter Takt/Schlag; Knöpfe BPM ±10 (greift ab dem nächsten Takt).

## Ansage-Stimme (Piper, englisch)

Uli hat am 18.10. entschieden: **Stimme englisch** (nicht deutsch).
Werkzeug: Piper 1.8.0 (Offline-Sprachsynthese), Skript
`tool/stimme/spike_clip.sh`. Piper liefert 22,05 kHz, das Skript rechnet auf
44,1 kHz mono um.

Testsatz „Next up: add the bass drum on the and of three." + Countdown
„three, two, one, go".

### Lizenzen (wichtig für den Verkauf der App)

| Stimme | Daten | Lizenz | Ergebnis |
|---|---|---|---|
| en_US-**ljspeech**-high | LJ Speech, von Grund auf trainiert | **Public Domain** | erlaubt |
| en_GB-**cori**-high | LibriVox, von Grund auf trainiert | **Public Domain** | erlaubt |
| en_US-norman-medium | LibriVox | Public Domain | erlaubt, aber unbrauchbar (erfindet bei Einzelwörtern 2,5 s Geräusch) |
| en_US-lessac-high, amy, en_GB-alan, joe, de_DE-thorsten | lessac oder davon abgeleitet („finetuned from lessac") | lessac = **Forschungslizenz** (Blizzard 2013) | **nicht** verwenden – Abstammung unklar für kommerziell |
| en_US-ryan, hfc_male/female | – | CC BY-NC-SA (nicht kommerziell) | **nicht** verwenden |

Piper selbst steht unter GPL-3.0. Das betrifft nur das Werkzeug beim
Katalog-Bau auf unserem Rechner. Die erzeugten WAV-Dateien fallen nicht
darunter, und Piper kommt nicht in die App.

### Messung der Clips

| | ljspeech-high | cori-high |
|---|---|---|
| Satz-Länge | 3,11 s (274 KB) | 2,53 s (223 KB) |
| Countdown-Wörter | 0,29–0,38 s | 0,55–0,65 s |
| Spracherkennung (Whisper, als grober Verständlichkeits-Test) | Satz richtig; „one" → „Bye", „three" → „Free" | Satz fast richtig („I have" statt „add"); Countdown 4/4 richtig |

Alle Dateien < 400 KB. Bei „and of three" hört die Erkennung bei beiden „end
of 3". Das ist ein typisches Problem der Erkennung, aber Uli sollte es anhören.

**Abwägung:** cori spricht die Countdown-Wörter deutlicher, sie sind aber
länger. Bei 180 BPM dauert ein Schlag 0,33 s, ein cori-Wort läuft dann in den
nächsten Schlag hinein. Das ist erlaubt (das Wort beginnt auf seinem Schlag,
wird nie gedehnt), klingt aber gedrängter. ljspeech passt zeitlich besser, ist
als Einzelwort aber weniger klar. → **Uli entscheidet nach Gehör.**
Im Spike eingebaut ist ljspeech.

## Messergebnisse

### (a) Lücken/Knacksen an Taktgrenzen — objektiv: keine

Prüfung am Rechner (`tool/spike_stream_render.dart` auf dem Spike-Branch):
150 Takte werden genau so Takt für Takt erzeugt, wie die App sie anhängt.
Das Ergebnis wird mit einer unabhängigen Berechnung „alles in einem Stück"
verglichen.

- Größte Abweichung: **0,00000007** (Rechen-Rundung, unhörbar). Das
  Aneinanderhängen der Takte erzeugt also **nichts**, was nicht auch in einem
  durchgehenden Stück wäre, auch nicht bei den 9 Tempowechseln.
- Warum das klappt: Jeder Klang (auch ein ausklingender Hi-Hat oder der
  3-s-Satz) liegt auf einer durchgehenden Zeitachse und läuft über die
  Taktgrenze einfach weiter.
- Lautstärke: Spitze 0,98 (Begrenzer greift), aber nur bei **0,22 %** aller
  Samples über der Begrenzer-Schwelle, und zwar dort, wo Stimme und Schlag
  zusammenfallen.
- Taktlängen sind ganze Samples. Ein Tempo wirkt immer genau ab einer Eins.

Ob der Übergang auch **am Gerät** sauber klingt (also ob SoLoud beim
Nachschieben nichts verschluckt), kann nur das Ohr bestätigen → *Uli prüft*.
Messbarer Hinweis darauf ist (d): kein einziger Puffer-Unterlauf.

### (b) Abspiel-Uhr läuft gleichmäßig — Emulator: ja

Emulator „s23" auf dem NUC, 150 Takte, 332,7 s Audio:

- 16 602 Abfragen von `getPosition` (alle 20 ms): **0 Rücksprünge**.
- Uhr gegen Wanduhr: Audio-Ende 332,7 s, Wanduhr 332,8 s, also keine Drift.
- Rechnen + Anhängen eines Takts: höchstens **37 ms** (auf dem Haupt-Thread,
  im Emulator).
- Kleinster Vorlauf vor der Abspielstelle: **1,29 s** (bei 180 BPM, ein Takt =
  1,33 s). Das reicht weit.

Achtung: Der Emulator läuft ohne Tonausgabe (`-no-audio`), die Uhr kommt
dort von SoLoud's Ersatz-Ausgabe. Die Abweichung „berechneter Schlag gegen
Ohr" (< 10 ms) geht nur am echten Gerät → *Uli prüft*.

### (c) Stimme + Schlagzeug gleichzeitig

Die Stimme wird **in denselben Klang hineingerechnet**, es gibt also keinen
zweiten Player und kein Android-„Ducking" (Leiserregeln anderer Töne). Im
Emulator keine Aussetzer. Ob es angenehm klingt (Lautstärke-Verhältnis
Stimme/Schlagzeug) → *Uli prüft*.

### (d) Puffer-Unterlauf

`onBuffering` wurde **0-mal** gemeldet (150 Takte, 9 Tempowechsel).

### (e) Speicher

App-Speicher (RSS) 377 MB beim Start → **453 MB** nach 150 Takten (+76 MB).
Rechnerisch belegt der Stream 56 MiB für 5,5 min (Float32, „preserved" hält
alles fest). Für eine 5-Minuten-Übung ist das vertretbar. Für längere Übungen
oder Speicher-Druck auf dem Handy: `BufferingType.released` (gibt Gespieltes
frei). Dann liefert `getPosition` aber immer 0, und die Uhr muss aus
`getStreamTimeConsumed` kommen. Das ist für Plan 1 nicht nötig.

## Was noch offen ist (konnte ich nicht machen)

- **S23:** Das Handy war nicht angeschlossen und der Laptop ist seit ca. 20:40
  offline. Die APK liegt fertig auf dem NUC: `~/gefuehrt-spike.apk`
  (Debug, versionCode 1 wie alle bisherigen drum_coach-Builds; eine höhere
  Nummer hätte spätere normale Builds blockiert).
- **Linux-Desktop:** Bundle nicht gebaut (Laptop offline).

## Uli prüft am Gerät

**Anhören am Rechner (sofort möglich, NUC):**

- `~/gefuehrt-spike-150takte.wav`: genau der Klang, den die App in 150 Takten
  abspielt (5,5 min, alle Tempowechsel, Stimme + Countdown). Auf Knackser an
  den Taktgrenzen achten, besonders bei den Tempowechseln (Takt 17, 33, 49,
  65, 81, 97, 113, 129, 141).
- `~/gefuehrt-stimmen/`: Satz + Countdown je Stimme (ljspeech, cori). Welche
  Stimme?

**S23** (wenn Laptop + Handy dran sind):

```bash
scp ~/gefuehrt-spike.apk laptop:~/agent-test-checkouts/
ssh laptop adb -s RFCW220PB7W install -r ~/agent-test-checkouts/gefuehrt-spike.apk
```

In der App: **Einstellungen → „SPIKE: stream test"** → **Auto 150** (läuft
5,5 min von allein mit allen Tempowechseln) oder **Manual** + BPM ±10.

Achten auf:
1. Knacksen oder Lücke an Taktgrenzen, vor allem beim Tempowechsel?
2. Läuft die Anzeige „bar · beat" im Takt mit dem, was du hörst? (Optional:
   Video mit Ton, dann vergleiche ich Klick und Anzeige < 10 ms.)
3. Stimme + Countdown gut verständlich, Lautstärke zum Schlagzeug passend?
4. Am Ende stehen „onBuffering events" und „position regressions" auf dem
   Schirm. Bitte ein Foto davon (sollte 0 / 0 sein).

**Linux-Desktop** (Laptop):

```bash
ssh laptop
cd ~/agent-test-checkouts/drum_coach-etappe2-phase-b
git fetch && git checkout spike/gefuehrt-stream && git reset --hard origin/spike/gefuehrt-stream
~/development/flutter/bin/flutter build linux --release
rsync -a --delete build/linux/x64/release/bundle/ ~/drum-coach-spike/
~/drum-coach-spike/drum_coach   # Einstellungen → SPIKE: stream test
```

## Empfehlung

**A: Stream-Architektur wie geplant**, unter Vorbehalt von Ulis Hörtest am
S23. Alles, was sich messen lässt, ist sauber: nahtlos per Konstruktion,
0 Unterläufe, Uhr gleichmäßig, Speicher vertretbar, Stimme ohne zweites
Audio-System. Rückfall B (vorgerenderte WAV je Abschnitt) nur, wenn Uli am
S23 Knackser oder Aussetzer hört.

Hinweis für Task 2/4: Die Stimmen-Sprache ist jetzt **Englisch**. Vorlage
für das Katalog-Werkzeug ist `tool/stimme/spike_clip.sh`
(`VOICE=…` wählt die Stimme). Spec §3.2 („Stimme Deutsch", `speechDe`) muss
entsprechend angepasst werden.

## Entscheidung (Gate, Task 0 Step 4)

- [ ] A Stream-Architektur  /  [ ] B Rückfall: ______
- Stimme: [ ] en_US-ljspeech-high  /  [ ] en_GB-cori-high
