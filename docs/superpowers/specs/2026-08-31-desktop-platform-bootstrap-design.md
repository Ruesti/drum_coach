# P1 — Desktop-Plattform-Bootstrap

**Datum:** 2026-08-31
**Teil von:** [Roadmap](2026-08-31-desktop-expansion-roadmap.md)
**Status:** Design, bereit zur Umsetzung

## Kontext

Erste Phase des Desktop-Ausbaus (siehe Roadmap). Ziel: die vorhandenen,
nie gebauten Flutter-Desktop-Scaffolds (linux/macos/windows) in einen
Zustand bringen, in dem der Kern-Übungsfluss tatsächlich läuft — als
Fundament für MIDI-Anbindung (P2) und Mehrspur-Content (P3) später.

## Warum das nötig ist

`docs/AUDIT.md` hält fest: Desktop-Scaffolds sind vorhanden, `flutter
analyze`/`test` laufen durch, aber es gibt keine CI, keine Build-Artefakte
und keinen Hinweis auf einen tatsächlichen End-to-End-Testlauf auf einer
der drei Desktop-Plattformen. macOS-Entitlements erlauben nur
Boilerplate-Rechte.

Eine Code-Prüfung während der Design-Phase hat zwei konkrete Risiken
bestätigt:

- `permission_handler` (Mikrofon-Anfrage) und `http` (Claude-API) hängen
  beide ausschließlich am AI-Coaching-Feature
  (`lib/features/coaching/services/mic_analysis_service.dart` bzw.
  `ai_coaching_service.dart`). Die Mikrofon-Anfrage feuert nur, wenn
  `SettingsService.micAnalysisEnabled` an ist — erreichbar ausschließlich
  über den „AI Coaching"-Abschnitt in `settings_screen.dart` (~Zeile 135).
- `flutter_local_notifications` (Version 17.0.0, **keine**
  Linux/Windows-Implementierung) wird dagegen direkt in `main.dart`, im
  Onboarding und in den Settings aufgerufen — also im Kernfluss, nicht
  hinter einem Feature-Schalter. Ohne Gating würde die App auf
  Windows/Linux vermutlich mit einer `MissingPluginException` beim Start
  abstürzen.

Die Git-Historie der Plattform-Ordner zeigt zudem, dass dort nie manuell
Entitlements gepflegt wurden — die aktuellen macOS-Entitlements sind
unverändertes `flutter create`-Boilerplate. Es gibt also nichts
Kundenspezifisches zu verlieren, wenn die Scaffolds neu generiert werden.

## Locked Decisions (mit dem Nutzer abgestimmt)

- **Ansatz B:** Scaffolds per `flutter create --platforms=linux,macos,windows .`
  neu generieren statt die bestehenden manuell zu flicken. Begründung: keine
  echten Custom-Entitlements vorhanden, nur Boilerplate + automatisch
  regenerierte Plugin-Registranten (siehe Commit „Regenerate macOS plugin
  registrant for record 7.1.1") — nichts zu verlieren, dafür eine
  garantiert zur aktuellen Flutter-Version passende Basis.
- **Kern-Übungsfluss ohne AI-Coaching:** Metronom, Notation/Sticking-Anzeige,
  Übungsnavigation und Fortschritt (Isar) müssen auf allen drei Desktop-OS
  laufen. AI-Coaching (Mikrofon-Analyse, Claude-API) bleibt vorerst
  Handy-exklusiv.
- **AI-Coaching wird auf Desktop komplett unsichtbar**, nicht nur
  deaktiviert oder mit „Coming soon" markiert — um keine Erwartung zu
  wecken, die nicht erfüllt wird. Die Route `/coaching/exercise-generator`
  bleibt technisch bestehen, ist aber von keinem UI-Element aus erreichbar.
- **Notifications sind auf allen drei Desktop-Plattformen No-Op** — auch
  auf macOS, obwohl `flutter_local_notifications` es dort unterstützen
  würde. Konsistenz vor Teil-Funktionalität; echter
  Desktop-Notification-Support ist ein späteres, eigenes Thema.
- **Kein Desktop-Redesign in P1** — nur eine Breiten-Deckelung des
  bestehenden Contents, damit die Handy-optimierte UI in einem großen
  Fenster nicht zur gestreckten Spalte wird. Echtes Desktop-Layout ist P4.
- **Definition of Done unterscheidet sich pro OS:** Windows (Nutzer-PC mit
  Superior Drummer) und Linux (Laptop) werden manuell verifiziert; macOS
  gilt als erfüllt, wenn der CI-Build grün ist — keine Laufzeit-Verifikation,
  da kein Testgerät vorhanden.

## Architektur

### 1. Scaffold-Neugenerierung

`flutter create --platforms=linux,macos,windows .` im Repo-Root. Das
überschreibt nur die Plattform-Runner-Dateien, nicht `lib/`/`pubspec.yaml`.
Anschließend `flutter pub get`, damit die Plugin-Registranten (Isar,
flutter_soloud, etc.) für die frischen Scaffolds neu gezogen werden.

### 2. Entitlements/Config nach der Neugenerierung

Für den AI-Coaching-freien Kernfluss ist **kein** zusätzliches Entitlement
nötig: kein Mikrofon, kein `network.client` (da `http` nur im
Coaching-Service steckt, der auf Desktop unerreichbar ist). Isar
(Dateisystem) und `flutter_soloud` (Audio-Ausgabe) laufen ohne
Sonderrechte im App-Sandbox-Container. Die frisch generierten
Default-Entitlements bleiben unverändert; falls der `flutter build`-Lauf
auf einer Plattform doch fehlende Rechte meldet, wird gezielt nachgezogen
(nicht vorab spekulativ).

### 3. Feature-Gating: AI-Coaching

Neues Hilfsmodul `lib/app/platform_support.dart`:

```dart
bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

bool get aiCoachingAvailable => !isDesktopPlatform;
```

`settings_screen.dart` rendert den kompletten „AI Coaching"-Block
(Mikrofon-Toggle + Link zu `/coaching/exercise-generator`) nur, wenn
`aiCoachingAvailable` true ist. Da `Permission.microphone.request()` in
`practice_session_screen.dart` durch `SettingsService.micAnalysisEnabled`
gated ist und dieser Schalter auf Desktop nie auf `true` gesetzt werden
kann (UI dazu ist ausgeblendet), wird `permission_handler` auf Desktop nie
aufgerufen.

### 4. Notifications: No-Op auf Desktop

`notification_service.dart` bekommt einen frühen Return-Zweig für
`isDesktopPlatform`: Scheduling-/Init-Aufrufe werden übersprungen, keine
Plugin-Calls, kein Crash, keine Fake-Erinnerungen. Aufrufstellen
(`main.dart`, Onboarding, Settings) bleiben unverändert — die Prüfung
sitzt zentral im Service.

### 5. Layout: Inhaltsbreite deckeln

Ein `ConstrainedBox`/`maxWidth` (Richtwert: ~480–600px, an bestehende
Design-Tokens angelehnt) um den Root-Content in der Shell, zentriert im
restlichen Fensterbereich. Kein sonstiges Layout-Redesign.

### 6. CI-Matrix

Neuer Workflow `.github/workflows/desktop-build.yml` mit drei Jobs
(`ubuntu-latest`, `windows-latest`, `macos-latest`):
`flutter pub get` → `flutter analyze` → `flutter test` →
`flutter build <platform> --release`. Läuft bei jedem Push/PR und schützt
die Desktop-Builds automatisch vor Regressionen aus der parallelen
Mobile-Feature-Arbeit (aktuell viele offene Branches).

## Betroffene/neue Dateien

- `linux/`, `macos/`, `windows/` — neu generiert von `flutter create`.
- `lib/app/platform_support.dart` — NEU (`isDesktopPlatform`,
  `aiCoachingAvailable`).
- `lib/features/settings/settings_screen.dart` — AI-Coaching-Block
  bedingt rendern.
- `lib/services/notification_service.dart` — Desktop-No-Op-Zweig.
- Root-Shell-Widget (Bottom-Navigation-Container) — Breiten-Deckelung.
- `.github/workflows/desktop-build.yml` — NEU (CI-Matrix).
- Tests: `platform_support_test.dart` (unit), Widget-Test für die
  Settings-Gating-Logik, Unit-Test für den Notification-Desktop-Zweig.
- `docs/CLAUDE.md` — kurze Ergänzung, dass Desktop (Windows/macOS/Linux)
  jetzt Kernfluss-Ziel ist, nicht mehr nur „Android-first"; verhindert
  Doku-Drift.

## Teststrategie

- **`platform_support.dart`:** reine Unit-Tests über eine injizierbare
  Override-Möglichkeit (kein echtes `Platform.isX`-Mocking nötig für die
  Kern-Fälle mobil vs. Desktop).
- **Settings-Screen:** Widget-Test, der den AI-Coaching-Block bei
  `aiCoachingAvailable: false` nicht rendert und bei `true` weiterhin wie
  bisher.
- **Notification-Service:** Unit-Test mit einem Fake/Mock statt des echten
  Plugins, der bestätigt, dass auf Desktop keine Plugin-Aufrufe erfolgen.
- **CI-Matrix** ist die Verifikation für „baut sauber auf allen drei OS".
- **Gerätetest (echtes Verhalten):** Windows-PC + Linux-Laptop über die
  `cross-machine-test-deploy`-Skill — Kernfluss durchspielen (Metronom,
  Notation-Anzeige, Übungsnavigation, Fortschritt bleibt nach Neustart
  erhalten). macOS: kein Gerätetest, nur CI-Ergebnis.

## Nicht-Ziele (P1)

- Kein Desktop-spezifisches Layout/Redesign (P4).
- Keine MIDI-Anbindung ans E-Kit (P2).
- Kein Mehrspur-Content (P3).
- AI-Coaching wird nicht auf Desktop nachgezogen — bleibt bewusst
  vollständig aus.
- Kein echter Desktop-Notification-Support (z. B. über eine
  Linux/Windows-fähige Alternative) — bewusstes No-Op.
- iOS bleibt außerhalb des Scopes (siehe `docs/CLAUDE.md`, „Future
  Roadmap").
