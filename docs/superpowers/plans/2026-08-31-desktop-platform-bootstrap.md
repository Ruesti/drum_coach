# Desktop-Plattform-Bootstrap (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DrumCoach läuft im Kern-Übungsfluss (Metronom, Notation, Navigation, Fortschritt) auf Windows, macOS und Linux, ohne dass Handy-only-Features (AI-Coaching, lokale Notifications) beim Start crashen.

**Architecture:** Ein zentraler Plattform-Helfer (`platform_support.dart`) entscheidet, ob eine Desktop-Plattform vorliegt. Zwei Verbraucher lesen ihn: der `NotificationService` (No-Op auf Desktop, weil `flutter_local_notifications` 17.0.0 keine Linux/Windows-Implementierung hat) und der Settings-Screen (blendet den AI-Coaching-Block auf Desktop komplett aus). Die bestehende Handy-UI wird in der Bottom-Nav-Shell auf eine maximale Inhaltsbreite gedeckelt. Die Desktop-Scaffolds werden per `flutter create` frisch generiert; eine GitHub-Actions-Matrix baut alle drei OS bei jedem Push.

**Tech Stack:** Flutter 3.44 (stable), Dart 3, Riverpod, go_router, Isar, flutter_soloud, flutter_local_notifications, shared_preferences.

## Global Constraints

- Flutter-Kanal **stable**, Version 3.44.x (lokal verifiziert: 3.44.4).
- **Kein** zusätzliches macOS-Entitlement in P1 — kein Mikrofon, kein `network.client` (AI-Coaching bleibt auf Desktop unerreichbar).
- Desktop = `Platform.isLinux || Platform.isMacOS || Platform.isWindows`; Notifications sind auf **allen dreien** No-Op (auch macOS), AI-Coaching auf allen dreien unsichtbar.
- AI-Coaching wird **ausgeblendet, nicht deaktiviert** — kein „Coming soon", kein leerer Platzhalter. Die Route `/coaching/exercise-generator` bleibt technisch bestehen, ist aber von keinem UI-Element aus erreichbar.
- **Kein** Desktop-Redesign — nur eine Breiten-Deckelung des bestehenden Contents. Echtes Desktop-Layout ist P4.
- UI-Strings folgen der bestehenden gemischten Konvention der Datei (Settings-Screen ist deutsch); keine neuen sichtbaren Strings nötig.
- Definition of Done pro OS: Windows + Linux manuell verifiziert (Nutzer-PC / Laptop), macOS nur CI-Build-grün.
- Diese Maschine (NUC) ist headless: `flutter analyze` + `flutter test` laufen hier; echte Desktop-Builds/-Runs laufen in CI bzw. auf den Nutzer-Maschinen.

---

### Task 1: Plattform-Helfer `platform_support.dart`

**Files:**
- Create: `lib/app/platform_support.dart`
- Test: `test/app/platform_support_test.dart`

**Interfaces:**
- Consumes: nichts (Blattknoten).
- Produces:
  - `bool get isDesktopPlatform` — true auf Linux/macOS/Windows, false auf Web/Android/iOS.
  - `bool get aiCoachingAvailable` — `!isDesktopPlatform`.
  - `bool? debugIsDesktopOverride` (`@visibleForTesting`) — wenn nicht null, überschreibt `isDesktopPlatform` das Ergebnis. Tests in Task 2 und 3 setzen diese Variable.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/platform_support_test.dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugIsDesktopOverride = null);

  test('override true → desktop, coaching unavailable', () {
    debugIsDesktopOverride = true;
    expect(isDesktopPlatform, isTrue);
    expect(aiCoachingAvailable, isFalse);
  });

  test('override false → not desktop, coaching available', () {
    debugIsDesktopOverride = false;
    expect(isDesktopPlatform, isFalse);
    expect(aiCoachingAvailable, isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/platform_support_test.dart`
Expected: FAIL — `Error: Not found: package:drum_coach/app/platform_support.dart` (Datei existiert noch nicht).

- [ ] **Step 3: Write minimal implementation**

```dart
// lib/app/platform_support.dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

/// Test-only override. When non-null, [isDesktopPlatform] returns this value
/// instead of probing the real OS. Reset to null in tearDown.
@visibleForTesting
bool? debugIsDesktopOverride;

/// True on the three Flutter desktop targets. False on web and mobile.
bool get isDesktopPlatform {
  final override = debugIsDesktopOverride;
  if (override != null) return override;
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

/// AI coaching (mic analysis + Claude API) ships mobile-only in Phase 1.
bool get aiCoachingAvailable => !isDesktopPlatform;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/platform_support_test.dart`
Expected: PASS (2 Tests).

- [ ] **Step 5: Commit**

```bash
git add lib/app/platform_support.dart test/app/platform_support_test.dart
git commit -m "feat(platform): add isDesktopPlatform + aiCoachingAvailable helper"
```

---

### Task 2: NotificationService No-Op auf Desktop

**Files:**
- Modify: `lib/services/notification_service.dart`
- Test: `test/services/notification_service_desktop_test.dart`

**Interfaces:**
- Consumes: `isDesktopPlatform`, `debugIsDesktopOverride` aus Task 1.
- Produces: `NotificationService.init()`, `scheduleDailyReminder()`, `cancelReminder()` returnen früh (ohne Plugin-Channel-Call), wenn `isDesktopPlatform`.

- [ ] **Step 1: Write the failing test**

```dart
// test/services/notification_service_desktop_test.dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Binding exists but no platform-channel handlers are registered, so any
  // real flutter_local_notifications call would throw MissingPluginException.
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugIsDesktopOverride = null);

  test('init() is a no-op on desktop (no plugin channel call)', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.init(), completes);
  });

  test('scheduleDailyReminder() is a no-op on desktop', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.scheduleDailyReminder(), completes);
  });

  test('cancelReminder() is a no-op on desktop', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.cancelReminder(), completes);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/services/notification_service_desktop_test.dart`
Expected: FAIL — die echten Methoden rufen `_plugin.initialize()` / `_plugin.zonedSchedule()` / `_plugin.cancel()` auf, was ohne registrierten Plugin-Handler eine `MissingPluginException` wirft; die Futures completen mit Fehler, `completes` schlägt fehl.

- [ ] **Step 3: Write minimal implementation**

Am Kopf der Datei den Import ergänzen:

```dart
import '../app/platform_support.dart';
```

Danach in jede der drei Methoden **ganz oben** einen Desktop-Guard einfügen. `init()`:

```dart
  static Future<void> init() async {
    if (isDesktopPlatform) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    if (SettingsService.reminderEnabled) {
      await scheduleDailyReminder();
    }
  }
```

`scheduleDailyReminder()` — erste Zeile im Body:

```dart
  static Future<void> scheduleDailyReminder() async {
    if (isDesktopPlatform) return;
    await _plugin.cancel(_notificationId);
    // … rest unverändert …
  }
```

`cancelReminder()` von Expression-Body auf Block-Body mit Guard umstellen:

```dart
  static Future<void> cancelReminder() async {
    if (isDesktopPlatform) return;
    await _plugin.cancel(_notificationId);
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/services/notification_service_desktop_test.dart`
Expected: PASS (3 Tests).

- [ ] **Step 5: Commit**

```bash
git add lib/services/notification_service.dart test/services/notification_service_desktop_test.dart
git commit -m "feat(notifications): no-op on desktop (plugin has no linux/windows impl)"
```

---

### Task 3: AI-Coaching im Settings-Screen auf Desktop ausblenden

**Files:**
- Modify: `lib/features/settings/settings_screen.dart:135-214`
- Test: `test/features/settings/settings_coaching_gating_test.dart`

**Interfaces:**
- Consumes: `aiCoachingAvailable`, `debugIsDesktopOverride` aus Task 1.
- Produces: Der komplette Block „AI COACHING" (Section-Label, Mikrofon-Tile, Claude-API-Key-Card, Exercise-Generator-Card) wird nur gerendert, wenn `aiCoachingAvailable`.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/settings/settings_coaching_gating_test.dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });
  tearDown(() => debugIsDesktopOverride = null);

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('hides AI COACHING section on desktop', (tester) async {
    debugIsDesktopOverride = true;
    await pumpSettings(tester);
    expect(find.text('AI COACHING'), findsNothing);
    expect(find.text('Mikrofon-Analyse'), findsNothing);
  });

  testWidgets('shows AI COACHING section on mobile', (tester) async {
    debugIsDesktopOverride = false;
    await pumpSettings(tester);
    expect(find.text('AI COACHING'), findsOneWidget);
    expect(find.text('Mikrofon-Analyse'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/settings/settings_coaching_gating_test.dart`
Expected: FAIL — `hides AI COACHING section on desktop` findet „AI COACHING" trotzdem (`findsNothing` erwartet, `findsOneWidget` real), weil der Block noch unbedingt gerendert wird.

- [ ] **Step 3: Write minimal implementation**

Import am Dateikopf ergänzen (nach den bestehenden relativen Imports):

```dart
import '../../app/platform_support.dart';
```

Den zusammenhängenden AI-Coaching-Abschnitt in der `ListView`-`children`-Liste (aktuell Zeile 135 „AI COACHING"-Label bis Zeile 214, die schließende Klammer der Exercise-Generator-`AppCard`) durch einen Spread ersetzen, der nur auf Mobil einfügt. Konkret den bisherigen Block:

```dart
          // ── AI Coaching ────────────────────────────────────────────────
          _SectionLabel('AI COACHING'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.mic_outlined,
            title: 'Mikrofon-Analyse',
            subtitle: 'Misst Timing & Dynamik während der Session',
            value: _micEnabled,
            onChanged: _setMicEnabled,
          ),
          const SizedBox(height: 12),
          AppCard(
            // … Claude API Key card (unverändert) …
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: () => context.push('/coaching/exercise-generator'),
            child: ListTile(
              // … Exercise Generator (unverändert) …
            ),
          ),
          const SizedBox(height: 8),
```

umschließen mit:

```dart
          // ── AI Coaching (mobile-only in Phase 1) ─────────────────────────
          if (aiCoachingAvailable) ...[
            _SectionLabel('AI COACHING'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: Icons.mic_outlined,
              title: 'Mikrofon-Analyse',
              subtitle: 'Misst Timing & Dynamik während der Session',
              value: _micEnabled,
              onChanged: _setMicEnabled,
            ),
            const SizedBox(height: 12),
            AppCard(
              // … Claude API Key card (unverändert) …
            ),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              onTap: () => context.push('/coaching/exercise-generator'),
              child: ListTile(
                // … Exercise Generator (unverändert) …
              ),
            ),
            const SizedBox(height: 8),
          ],
```

Wichtig: Der Spread-Block endet **vor** der „Onboarding erneut zeigen"-`AppCard` (die bleibt außerhalb und sichtbar). Die trailing `const SizedBox(height: 8)` gehört mit in den Block, damit auf Desktop kein doppelter Abstand vor der Onboarding-Card entsteht.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/settings/settings_coaching_gating_test.dart`
Expected: PASS (2 Tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/settings_screen.dart test/features/settings/settings_coaching_gating_test.dart
git commit -m "feat(settings): hide AI coaching section on desktop"
```

---

### Task 4: Inhaltsbreite in der Bottom-Nav-Shell deckeln

**Files:**
- Modify: `lib/app/design_tokens.dart:53` (neue Konstante nach `AppSpacing`)
- Modify: `lib/app/router.dart:133-137` (`_ScaffoldWithNavBar.build`)
- Test: `test/app/content_width_cap_test.dart`

**Interfaces:**
- Consumes: nichts Neues aus früheren Tasks.
- Produces: `AppLayout.maxContentWidth` (double). `_ScaffoldWithNavBar` umschließt `navigationShell` mit `Center` + `ConstrainedBox(maxWidth: AppLayout.maxContentWidth)`.

- [ ] **Step 1: Write the failing test**

```dart
// test/app/content_width_cap_test.dart
import 'package:drum_coach/app/design_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maxContentWidth is a sane desktop cap', () {
    expect(AppLayout.maxContentWidth, greaterThan(400));
    expect(AppLayout.maxContentWidth, lessThanOrEqualTo(700));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/app/content_width_cap_test.dart`
Expected: FAIL — `Undefined name 'AppLayout'` (Konstante existiert noch nicht).

- [ ] **Step 3: Write minimal implementation**

In `lib/app/design_tokens.dart` direkt nach der schließenden Klammer von `AppSpacing` (Zeile 53) eine neue Klasse einfügen:

```dart
/// Layout limits. On large (desktop) windows the phone-first UI is capped to
/// this width and centered, so it never stretches into an unreadable column.
class AppLayout {
  AppLayout._();

  static const maxContentWidth = 560.0;
}
```

In `lib/app/router.dart` den Import für die Tokens ergänzen (falls nicht vorhanden — prüfen; die Datei importiert aktuell keine design_tokens):

```dart
import 'design_tokens.dart';
```

Dann in `_ScaffoldWithNavBar.build` den `body` umschließen:

```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppLayout.maxContentWidth,
          ),
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // … unverändert …
      ),
    );
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/app/content_width_cap_test.dart`
Expected: PASS (1 Test).

- [ ] **Step 5: Full suite + analyze (Regression-Gate)**

Run: `flutter analyze && flutter test`
Expected: analyze ohne Fehler; alle Tests grün (bestehende + neue aus Tasks 1–4).

- [ ] **Step 6: Commit**

```bash
git add lib/app/design_tokens.dart lib/app/router.dart test/app/content_width_cap_test.dart
git commit -m "feat(layout): cap content width and center in bottom-nav shell"
```

---

### Task 5: Desktop-Scaffolds neu generieren + Doku-Angleich

**Files:**
- Regenerate: `linux/`, `macos/`, `windows/` (via `flutter create`)
- Modify: `docs/CLAUDE.md` (Zeile 3–4, „Android-first" → Desktop ist jetzt Kernfluss-Ziel)

**Interfaces:**
- Consumes: nichts.
- Produces: frische, zur Flutter-3.44-Version passende Plattform-Runner für alle drei Desktop-OS.

- [ ] **Step 1: Sicherheits-Check vor Regenerierung**

Run: `git status --short`
Expected: sauberer Baum (alle vorherigen Tasks committed). Falls nicht — erst committen/aufräumen, bevor `flutter create` läuft.

- [ ] **Step 2: Scaffolds neu generieren**

Run: `flutter create --platforms=linux,macos,windows --project-name drum_coach .`
Expected: Ausgabe listet neu erstellte/überschriebene Dateien unter `linux/`, `macos/`, `windows/`. `lib/`, `pubspec.yaml`, `test/` bleiben unangetastet.

- [ ] **Step 3: Dependencies neu ziehen**

Run: `flutter pub get`
Expected: „Got dependencies!" ohne Fehler.

- [ ] **Step 4: Analyze + Tests weiterhin grün**

Run: `flutter analyze && flutter test`
Expected: keine neuen Analyzer-Fehler; alle Tests grün. (Die Regenerierung ändert keinen Dart-Code, dient nur als Sanity-Check, dass nichts an der Projektkonfiguration kaputtging.)

- [ ] **Step 5: Doku angleichen**

In `docs/CLAUDE.md` den Kopf (Zeile 3–4) von:

```
Android app for training and improving drum rudiments on a practice pad.
Flutter, Android-first. iOS support may follow later.
```

ändern zu:

```
App for training and improving drum rudiments on a practice pad.
Flutter. Android + Desktop (Windows/macOS/Linux) are supported core-flow
targets (see docs/superpowers/specs/2026-08-31-desktop-expansion-roadmap.md);
AI coaching remains mobile-only for now. iOS may follow later.
```

- [ ] **Step 6: Commit**

```bash
git add linux macos windows docs/CLAUDE.md
git commit -m "chore(desktop): regenerate linux/macos/windows scaffolds + doc alignment"
```

---

### Task 6: CI-Matrix für Desktop-Builds

**Files:**
- Create: `.github/workflows/desktop-build.yml`

**Interfaces:**
- Consumes: nichts.
- Produces: Ein Workflow, der bei jedem Push/PR auf `ubuntu-latest`, `windows-latest`, `macos-latest` `flutter build <platform> --release` (plus analyze/test) ausführt.

- [ ] **Step 1: Workflow schreiben**

```yaml
# .github/workflows/desktop-build.yml
name: Desktop Build

on:
  push:
  pull_request:

jobs:
  build:
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-latest
            target: linux
          - os: windows-latest
            target: windows
          - os: macos-latest
            target: macos
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4

      - name: Install Linux desktop build deps
        if: matrix.target == 'linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y ninja-build libgtk-3-dev

      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: 3.44.4

      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build ${{ matrix.target }} --release
```

- [ ] **Step 2: YAML lokal auf Gültigkeit prüfen**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/desktop-build.yml')); print('valid yaml')"`
Expected: `valid yaml` (kein Traceback).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/desktop-build.yml
git commit -m "ci: build linux/windows/macos on every push"
```

- [ ] **Step 4: Push + CI-Ergebnis beobachten**

```bash
git push
```
Nach dem Push den Workflow-Lauf prüfen:

Run: `gh run list --workflow=desktop-build.yml --limit 1`
Dann den neuesten Lauf beobachten: `gh run watch`
Expected (Ziel-Zustand): alle drei Matrix-Jobs grün. Dies ist die macOS-Verifikation (kein lokales Testgerät) sowie der Build-Nachweis für Linux/Windows.

---

## Geräteverifikation (nach der Umsetzung, außerhalb der Tasks)

Diese Schritte laufen **nicht** auf dem NUC. Über die `cross-machine-test-deploy`-Skill:

- **Linux (Laptop):** `flutter run -d linux`, Kernfluss durchspielen — Metronom startet/tickt, Notation/Sticking-Anzeige rendert, Übungsnavigation funktioniert, eine Session abschließen und App neu starten → Fortschritt (Isar) ist erhalten. Settings öffnen → **kein** „AI COACHING"-Abschnitt sichtbar, kein Crash.
- **Windows (Nutzer-PC mit Superior Drummer):** identischer Durchlauf mit `flutter run -d windows`.
- **macOS:** kein Gerätetest — CI-Build-Grün aus Task 6 ist die Definition of Done.

---

## Self-Review-Notiz (Autor)

- **Spec-Abdeckung:** Scaffold-Regen (T5), AI-Coaching-Gating (T3), Notification-No-Op (T2), Breiten-Cap (T4), CI-Matrix (T6), Doku-Angleich (T5), `platform_support` (T1) — jede Spec-Sektion hat eine Task.
- **Entitlements:** Die Spec sagt „kein zusätzliches Entitlement in P1, nur bei Build-Fehler nachziehen". Deshalb gibt es bewusst keine Entitlement-Task; falls ein CI-Build (T6) an fehlenden Rechten scheitert, wird der Fix dort reaktiv ergänzt. Das ist im Global-Constraints-Block festgehalten.
- **Typ-Konsistenz:** `isDesktopPlatform` / `aiCoachingAvailable` / `debugIsDesktopOverride` (T1) werden in T2/T3 mit exakt diesen Namen konsumiert; `AppLayout.maxContentWidth` (T4) einheitlich.
