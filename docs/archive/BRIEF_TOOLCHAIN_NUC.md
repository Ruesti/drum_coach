# BRIEF: Flutter/Dart Toolchain auf dem NUC (Build- & Test-Host)

> **Rolle:** Setup-Task, vom Handy angestoßen, headless auf dem NUC.
> **Zweck:** Den NUC zum reinen **Build-/Test-Host** machen — `flutter analyze`,
> `dart run build_runner build`, Unit-Tests laufen. **Kein** Emulator, **kein**
> Display, **kein** App-Start (der finale UI-Test passiert auf Laptop/PC).
> **Voraussetzung fürs Feature:** `BRIEF_TRAINING_PROGRAM.md` wartet auf grüne
> Toolchain und startet erst danach.

---

## §0 · Interview-Gate — ZUERST

Aus dem Host beantworten, bei Unklarheit zurückfragen statt raten:

1. **OS & Arch:** `uname -m` (x86_64 erwartet), Distro/Version. Nur damit der
   richtige SDK-Weg gewählt wird.
2. **Schon was da?** `which flutter dart; ls ~/flutter 2>/dev/null; snap list 2>/dev/null | grep -i flutter`.
   Falls doch eine Installation existiert → nur PATH reparieren, nicht neu klonen.
3. **Netz:** Ist `github.com` / `storage.googleapis.com` vom NUC erreichbar?
   (SDK + erster `flutter precache` ziehen von dort.)
4. **Zielversion:** Welchen Flutter-Channel/Version braucht `drum_coach`?
   Prüfe `drum_coach/pubspec.yaml` (`environment: sdk:` / evtl. `.fvmrc` oder
   `.tool-versions`). SDK-Version daran ausrichten, nicht blind „latest stable".

**Erst nach §0 loslegen.**

---

## 1 · Scope

- Flutter-SDK **headless** installieren (git-clone-Methode, kein snap — snap ist
  auf Servern oft zickig und braucht root):
  ```bash
  git clone https://github.com/flutter/flutter.git -b stable ~/flutter
  ```
  (Branch/Tag an §0.4 anpassen, falls das Projekt eine bestimmte Version will.)
- PATH **dauerhaft** setzen (in `~/.bashrc` **und** `~/.profile`, damit sowohl
  interaktive SSH- als auch Nicht-Login-Shells des Agenten ihn sehen):
  ```bash
  export PATH="$PATH:$HOME/flutter/bin"
  ```
- `flutter config --no-analytics` und `flutter precache` einmalig ausführen.
- Projekt-Deps holen: im `drum_coach`-Root `flutter pub get`.

### Ausdrücklich OUT OF SCOPE
- **Keine** Android-SDK / NDK / Emulatoren / `flutter doctor`-Android-Toolchain.
  Für `analyze`, Codegen und Unit-Tests unnötig — die brauchen nur das Dart/Flutter-SDK.
- **Kein** `flutter build apk`/`appbundle` (Release-Signing läuft ohnehin
  woanders).
- Nichts am `drum_coach`-Code ändern. Dies ist reines Environment-Setup.
- Keine globale Systeminstallation, kein `sudo`, kein Paketmanager-Eingriff —
  alles unter `$HOME`.

---

## 2 · Arbeitsweise

- Klein, prüfbar, kein roter Zwischenstand. Jeder Schritt wird sofort verifiziert
  (Kommando + Output).
- Da **kein** Repo-Code angefasst wird, gibt es hier nichts zu committen. Falls
  du eine Setup-Notiz ablegen willst, dann als `SETUP_NUC.md` (untracked lassen
  oder separat committen — nicht in den Feature-Branch mischen).

---

## 3 · Budget & Stop

- SDK-Download + precache dauert und zieht viel — das ist Netzwerk, nicht Modell,
  also günstig. Falls trotzdem das Ceiling greift: sauberer Stopp, Zustand notieren
  (was steht, was fehlt), im Bericht der Wiederaufsetzpunkt.

---

## 4 · Definition of Done (beweisbar)

Jeder Punkt mit Output im Bericht:

- [ ] `flutter --version` läuft und zeigt die in §0.4 gewünschte Version. → Output.
- [ ] `dart --version` läuft. → Output.
- [ ] PATH überlebt eine **frische** Shell: neue Nicht-Login-Shell öffnen
      (`bash -c 'flutter --version'`) → muss funktionieren, nicht „command not found".
- [ ] Im `drum_coach`-Root: `flutter pub get` erfolgreich. → Output (letzte Zeilen).
- [ ] `flutter analyze` läuft **durch** (dass es grün ist, ist ideal; falls es
      bestehende Warnings/Fehler im Repo gibt, die *nicht* von uns stammen →
      auflisten, nicht fixen). → Output.
- [ ] `dart run build_runner build --delete-conflicting-outputs` läuft im Repo
      durch (der bestehende Codegen muss bauen, bevor wir neue Modelle draufsetzen).
      → letzte Zeilen des Outputs.

Wenn diese sechs stehen, ist der NUC build-fähig und das Feature kann starten.

---

## 5 · Bericht

`BERICHT_TOOLCHAIN_NUC.md` ins Arbeitsverzeichnis:
1. §0-Antworten (OS, gewählte Flutter-Version + warum, war schon was da).
2. DoD-Punkte je mit Proof-Output.
3. Falls `analyze`/`build_runner` schon vor unseren Änderungen meckert:
   die bestehenden Meldungen auflisten (das ist Baseline-Info fürs Feature,
   damit wir „unsere" von „alten" Fehlern trennen können).
4. Bestätigung, ob `BRIEF_TRAINING_PROGRAM.md` jetzt starten kann.

---

## Kickoff (auf dem NUC, in tmux)

```
cd /home/uli/projects/drum_coach
claude
> Lies BRIEF_TOOLCHAIN_NUC.md, arbeite §0 zuerst ab und halte für Rückfragen an,
> bevor du etwas installierst.
```

Danach — wenn der Bericht grün meldet — im selben oder neuen Lauf:
```
> Toolchain steht. Lies BRIEF_TRAINING_PROGRAM.md und STICK_CONTROL_PROGRAM.md,
> arbeite dessen §0 ab (mit den bereits getroffenen Entscheidungen aus dem
> vorigen BERICHT_TRAINING_PROGRAM.md) und beginne dann die Implementierung.
```
