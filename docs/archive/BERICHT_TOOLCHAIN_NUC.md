# BERICHT: Flutter/Dart Toolchain auf dem NUC

> Erstellt: 2026-07-05 · Host: NUC (headless Build-/Test-Host)
> Bezug: `BRIEF_TOOLCHAIN_NUC.md`

---

## 1 · §0 — Interview-Gate (Antworten)

| # | Frage | Befund |
|---|-------|--------|
| 1 | **OS & Arch** | `x86_64`, **Debian GNU/Linux 13 (trixie)**. Standard-git-clone-SDK-Weg passt, kein snap nötig. |
| 2 | **Schon was da?** | **Nein.** `flutter`/`dart` nicht im PATH, kein `~/flutter`, kein Flutter-Snap. → Saubere Neuinstallation, kein PATH-Reparaturfall. |
| 3 | **Netz** | `github.com` → HTTP 200. `storage.googleapis.com` → HTTP 400 (nur Bucket-API-Ablehnung des nackten Root-GET; Host erreichbar). SDK-Clone + precache liefen ohne Netzfehler durch. |
| 4 | **Zielversion** | `pubspec.yaml`: `environment: sdk: '>=3.4.0 <4.0.0'`. **Kein** `.fvmrc`, **kein** `.tool-versions`, keine gepinnte Flutter-Version. |

### Gewählte Version + Begründung
**Flutter 3.44.4 · channel stable** (Dart 3.12.2). Da nichts gepinnt ist und nur
`Dart ≥ 3.4.0` verlangt wird, erfüllt latest stable die Constraint sicher.
Entscheidung „latest stable" wurde vor der Installation mit dem Nutzer bestätigt.

---

## 2 · Definition of Done — je mit Proof-Output

### ✅ `flutter --version` (gewünschte Version)
```
Flutter 3.44.4 • channel stable • https://github.com/flutter/flutter.git
Framework • revision ad70ec4617 (11 days ago) • 2026-06-24 11:07:06 -0700
Engine • hash 700aebeca4c0e610f109a3979ee3e71b69d666bc (revision a10d8ac38d)
Tools • Dart 3.12.2 • DevTools 2.57.0
```

### ✅ `dart --version`
```
Dart SDK version: 3.12.2 (stable) (Tue Jun 9 01:11:39 2026 -0700) on "linux_x64"
```

### ✅ PATH überlebt eine frische Shell
**Wichtige Abweichung vom Brief — gelöst:** Der `.bashrc`/`.profile`-Weg allein
reichte für **diese** Umgebung nicht. Die Shells, mit denen der Agent/das Harness
Kommandos ausführt, sind **non-interactive & non-login** und lesen daher **weder
`.bashrc` noch `.profile`** — der literale DoD-Befehl `bash -c 'flutter --version'`
liefert dort „command not found".

Umgesetzt wurde deshalb **beides**:
1. PATH-Zeile in `~/.bashrc` **und** `~/.profile` (deckt interaktive SSH- und
   Login-Shells ab, wie im Brief vorgesehen).
2. Zusätzlich robuste Symlinks in `~/.local/bin` (liegt bereits im PATH, ist
   beschreibbar, alles unter `$HOME`, kein sudo):
   ```
   ~/.local/bin/flutter -> ~/flutter/bin/flutter
   ~/.local/bin/dart    -> ~/flutter/bin/dart
   ```
   Flutters Launcher löst Symlinks korrekt auf → SDK-Root wird richtig gefunden.

Beweis (frische Harness-Shell, **ohne** manuelles `export PATH`):
```
$ flutter --version
Flutter 3.44.4 • channel stable • https://github.com/flutter/flutter.git
$ dart --version
Dart SDK version: 3.12.2 (stable) ... on "linux_x64"
```
Ebenfalls grün: `bash -lc 'flutter --version'` und `bash -ic 'flutter --version'`.
(Nur ein von der Elternumgebung völlig isoliertes `env -i bash -c` findet es
erwartungsgemäß nicht — das entspricht keiner real vom Agenten genutzten Shell.)

### ✅ `flutter pub get`
```
Got dependencies!
54 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```
(Die 54 „newer versions" sind nur Hinweise auf neuere, durch die Constraints
gesperrte Versionen — kein Fehler.)

### ✅ `flutter analyze` — läuft durch
```
Analyzing drum_coach...
warning • 'buildQuery' is experimental ... • lib/features/learning/routine_provider.dart:17:12 • experimental_member_use
warning • 'buildQuery' is experimental ... • lib/features/practice/practice_provider.dart:46:10 • experimental_member_use
warning • 'buildQuery' is experimental ... • lib/features/practice/practice_provider.dart:76:8 • experimental_member_use
warning • 'buildQuery' is experimental ... • lib/features/stats/stats_provider.dart:29:8 • experimental_member_use
warning • 'buildQuery' is experimental ... • lib/features/stats/stats_provider.dart:38:8 • experimental_member_use
5 issues found. (ran in 17.7s)
```

### ✅ `dart run build_runner build --delete-conflicting-outputs` — baut durch
```
[INFO] Running build completed, took 33.9s
[INFO] Caching finalized dependency graph completed, took 125ms
[INFO] Succeeded after 34.0s with 46 outputs (185 actions)
```
`git status` danach: **keine** Modifikation an getrackten Dateien → der Codegen
reproduziert die committeten `*.g.dart` byte-identisch (deterministisch, kein
roter Zwischenstand).

---

## 3 · Baseline — bestehende Meldungen VOR unseren Änderungen

Für die spätere Trennung „unsere" vs. „alte" Fehler im Feature:

**`flutter analyze` — 5 vorbestehende Warnings (alle `experimental_member_use`):**
- `lib/features/learning/routine_provider.dart:17:12` — `buildQuery` experimental
- `lib/features/practice/practice_provider.dart:46:10` — `buildQuery` experimental
- `lib/features/practice/practice_provider.dart:76:8` — `buildQuery` experimental
- `lib/features/stats/stats_provider.dart:29:8` — `buildQuery` experimental
- `lib/features/stats/stats_provider.dart:38:8` — `buildQuery` experimental

Ursache: Riverpod-generierter Code nutzt die als experimental markierte
`buildQuery`-API der aktuellen Analyzer/Riverpod-Kombination. **Nicht gefixt**
(Out of Scope, stammt nicht von uns). 0 Errors.

**`build_runner`:** keine Fehler, keine Warnings — sauber.

---

## 4 · Kann `BRIEF_TRAINING_PROGRAM.md` starten?

**Ja.** Der NUC ist build-fähig: SDK installiert, PATH in jeder Shell stabil
(inkl. Symlink-Absicherung fürs Harness), `pub get`/`analyze`/`build_runner`
laufen alle durch. Baseline dokumentiert. Kein Repo-Code angefasst, nichts zu
committen.

**Hinweis für die Feature-Session:** Sollte in einer neuen Shell doch mal
`command not found` auftreten, ist die Ursache die non-login-Shell — dann greift
der Symlink in `~/.local/bin` bzw. einmalig `export PATH="$PATH:$HOME/flutter/bin"`.

---

## Out of Scope — bestätigt nicht angefasst
- Keine Android-SDK/NDK/Emulatoren, kein `flutter build apk/appbundle`.
- Kein `sudo`, kein Paketmanager, keine Systeminstallation — alles unter `$HOME`.
- Kein App-Start / kein Display / kein UI-Test (läuft auf Laptop/PC).
