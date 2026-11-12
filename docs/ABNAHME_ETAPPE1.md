# Abnahmeliste Etappe 1 (Test am echten Kit)

**Stand:** 12.11.2026, Branch `etappe1-kit`, App-Version 1.0.0+1.

## Welche Builds gibt es?

| Build | Stand | Pfad / Befehl |
|---|---|---|
| Linux (Release), NUC | gebaut, nur Kompilier-Test | `build/linux/x64/release/bundle/drum_coach` |
| Android APK (Release), NUC | gebaut (58,3 MB, minSdk 24) | `build/app/outputs/flutter-apk/app-release.apk` |
| Linux-Bundle fuer den Laptop | **offen** (Laptop war offline; muss dort gebaut werden wegen glibc) | auf dem Laptop im Repo: `flutter build linux --release` |
| Windows (Release) | **offen** (laptop-win war offline) | auf laptop-win im Repo-Checkout: `flutter build windows --release` |

**Vorsicht:** Den ALSA-Test (`tool/midi/virtual_port_test.sh`) nicht unter hoher CPU-Last starten (p95-Jitter kann dann reissen).

Automatische Pruefungen auf dem NUC: `flutter test` (150 gruen), `flutter analyze` (keine Meldungen), `bash tool/midi/virtual_port_test.sh` (gruen).

## 1. MegaDrum wird erkannt, Kit anlernen

| Erwartung | Befund | Datum |
|---|---|---|
| MegaDrum per USB wird unter Linux erkannt | Plattform: Linux. |  |
| MegaDrum per USB-OTG wird unter Android erkannt | Plattform: Android. |  |
| MegaDrum per USB wird unter Windows erkannt | Plattform: Windows. |  |
| Der Startbildschirm (Home) zeigt den Namen der MegaDrum als Geraet (bei mehreren MIDI-Eingaengen nimmt die App den ersten; andere MIDI-Geraete vorher abziehen) | Plattform: |  |
| Kit anlernen fuer Kick, Snare, Hi-Hat dauert unter 2 Minuten | Plattform: |  |
| Die Zuordnung (Mapping) ueberlebt einen Neustart der App | Plattform: |  |

## 2. Zeitstempel-Streuung (haengt an E2, Punkt 7)

Methode: das Loopback-Kabel aus Punkt 7 (Klick-Ausgang in einen Trigger-Eingang der MegaDrum). Nur so kommen 64 Schlaege mit bekanntem, gleichmaessigem Abstand ins Modul; ein Mensch spielt nicht auf 1 ms genau. Feuert der Trigger nicht sauber (Punkt 7 = nein), ist dieser Punkt **nicht pruefbar** und bleibt offen. Die Auswertung (Streuung der Abstaende zwischen Klick und Zeitstempel) gehoert zum Folgeplan aus Punkt 7.

| Erwartung | Befund | Datum |
|---|---|---|
| Linux: 64 Viertelnoten per Loopback-Kabel in die MegaDrum: Streuung der Zeitstempel unter 1 ms |  |  |
| Android: dasselbe, Streuung unter 1 ms |  |  |
| Windows: dasselbe, Streuung unter 1,5 ms |  |  |

## 3. Latenz-Kalibrierung

| Erwartung | Befund | Datum |
|---|---|---|
| Zwei Kalibrierungen direkt nacheinander weichen hoechstens 3 ms voneinander ab. Das prueft auch die Schaetzung des Klickstarts: weichen zwei Kalibrierungen um mehr als 3 ms ab, zuerst den Klickstart verdaechtigen |  |  |
| Wert, Geraet, Audio-Ausgang und Puffergroesse (SoLoud-Standard 2048 Samples, falls nicht geaendert) sind hier notiert (Bericht Abschnitt 4.1) |  |  |

## 4. Echte Sitzungen als Testdaten

| Erwartung | Befund | Datum |
|---|---|---|
| Pro Uebung zwei echte Sitzungen gespeichert als `test/fixtures/sessions/megadrum_*.jsonl` plus erwartetes JSON |  |  |
| Golden-Test mit diesen Dateien ist gruen und reproduzierbar |  |  |

## 5. Huerde "Basic Rock Beat"

| Erwartung | Befund | Datum |
|---|---|---|
| Bestanden/Durchgefallen ist aus der Huerden-Tabelle nachvollziehbar |  |  |
| Ein absichtlich schlampiger Durchlauf faellt am erwarteten Kriterium durch |  |  |

Hinweis: Das Hi-Hat-Pedal (Note 44) zaehlt im Rock Beat als Extraschlag. Also keine Fuss-Chicks mitspielen, sonst steigt die Extra-Rate.

## 6. Einstiegsuebung

| Erwartung | Befund | Datum |
|---|---|---|
| Ein Durchlauf, der nach Takt 4 abgebrochen wird, zeigt "Start with the basics first" |  |  |

## 7. E2 (offen): Loopback-Kabel

| Erwartung | Befund | Datum |
|---|---|---|
| Klick ueber Loopback-Kabel in den Trigger-Eingang der MegaDrum: feuert er sauber? Wenn ja: Folgeplan fuer objektive Latenzmessung |  |  |

## 8. Klick bei zweitem Start

| Erwartung | Befund | Datum |
|---|---|---|
| Dieselbe Uebung zweimal nacheinander starten: der erste Durchlauf darf zu Ende laufen, der zweite Klick startet sauber (kein Fehler beim Stoppen eines schon beendeten Klicks) |  |  |

## 9. Bildschirm waehrend Lauf verlassen

| Erwartung | Befund | Datum |
|---|---|---|
| Bildschirm waehrend Kalibrierung oder Durchlauf verlassen: Klick verstummt, der naechste Start ist normal |  |  |

## 10. Spuransicht am echten Bildschirm

| Erwartung | Befund | Datum |
|---|---|---|
| Abweichung von 15 ms ist in der Spuransicht erkennbar |  |  |
| Scrollen funktioniert |  |  |
| Antippen funktioniert |  |  |

