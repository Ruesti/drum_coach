# AUDIT — Bestandsaufnahme für BRIEF_DRUM_COACH_ERWEITERUNG.md

> Phase 0 gemäß Brief. Kein Code geändert, nichts gelöscht oder umbenannt.
> Stand: Branch `feature/training-program-stick-control` (identisch zu `main`, HEAD `d19c8fb`).
> Toolchain-Check: Flutter 3.44.4 / Dart 3.12.2 verfügbar, `flutter analyze` grün (5 Warnungen, siehe unten), `flutter test` grün (20/20 Tests).

---

## 1. Was existiert bereits?

**Verzeichnisstruktur** (`lib/`), feature-first:

```
lib/
├── app/{router.dart, theme.dart}
├── data/local/{isar_service.dart, settings_service.dart,
│               models/{practice_session.dart, rudiment_progress.dart}}
├── features/
│   ├── coaching/       — Mic-Analyse, Claude-Feedback, KI-Übungsgenerator (Phase 8)
│   ├── dashboard/
│   ├── learning/       — Spaced Repetition, BPM-Progression, Tages-Routine
│   ├── lessons/        — Rudiment-Katalog (statisch), Übungsplan
│   ├── metronome/       — Isolate-basierte Klick-Engine
│   ├── onboarding/
│   ├── practice/        — Übungssession, schreibt Fortschritt
│   ├── settings/
│   └── stats/
├── services/notification_service.dart
└── shared/widgets/notation_staff_widget.dart
```

**Architektur-Schichten**: Feature-first, **keine** strikte Data/Domain/Presentation-Trennung. Jeder `features/<x>/`-Ordner mischt Riverpod-Provider (State) direkt mit Screen (Presentation); wo sinnvoll gibt es einen puren Dart-Service (Business-Logik, z. B. `bpm_progression_service.dart`, `spaced_repetition_service.dart` — kein Flutter-Import, sauber testbar). Es gibt **keine Repository-Abstraktion**: Provider rufen `IsarService.instance` direkt auf (`practice_provider.dart:30-31`, `routine_provider.dart:16-18`, `stats_provider.dart:29,38`). Persistenz lässt sich damit nicht ohne Provider-Änderungen austauschen.

**State-Management**: Riverpod mit `@riverpod`-Codegen durchgängig (`pubspec.yaml`: `flutter_riverpod: ^2.6.1`, `riverpod_annotation: ^2.3.0`). Codegen aktuell, baut sauber. Kein rohes `setState` für Business-Logik gefunden.

**Persistenz**: Isar (`isar: ^3.1.0+1`). Nur zwei `@collection`s sind tatsächlich persistiert: `PracticeSession` und `RudimentProgress` (`data/local/isar_service.dart:11-17`). Nicht-transaktionale Settings (Onboarding-Flag, Praxisziel, Haptik, Erinnerungszeit, Claude-API-Key, Mic-Analyse-Toggle) liegen in `shared_preferences` (`data/local/settings_service.dart`, statisches Singleton).

**Wichtig**: `Rudiment` selbst ist **nicht persistiert** — es ist eine `const`-In-Memory-Liste (`features/lessons/data/rudiments_seed.dart`, ~1869 Zeilen, ~46 Einträge), exponiert über `lessons_provider.dart:9`.

**Sync-Pfad**: Keiner. Kein Backend, keine Auth. Kein Firebase/Supabase/eigener Server in `pubspec.yaml`. Der einzige Netzwerkaufruf im gesamten Code ist der direkte HTTPS-Call an die Anthropic-API aus `features/coaching/services/ai_coaching_service.dart:9` (`https://api.anthropic.com/v1/messages`) mit nutzereigenem API-Key.

**Testabdeckung**: 4 Testdateien, 20 Tests, alle grün.
- `test/learning/bpm_progression_test.dart` — 9 Tests, deckt `BpmProgressionService` gut ab.
- `test/learning/spaced_repetition_test.dart` — 5 Tests, deckt `SpacedRepetitionService` gut ab.
- `test/notation_staff_test.dart` — rendert jedes Seed-Rudiment durch `NotationStaffWidget`, plus 2 Tests zu `practicePlanProvider`-Ordering.
- `test/widget_test.dart` — Platzhalter-Stub (`expect(true, isTrue)`), nie ausgefüllt.

**Ungetestet**: `MetronomeEngine` (Isolate-Timing), alle Isar-berührenden Provider (kein In-Memory-Isar-Testharness vorhanden), `MicAnalysisService` (Onset-Detection-DSP), `AICoachingService` (Netzwerk + JSON-Parsing), praktisch alle Screens/Widgets außer dem Notation-Staff.

**5 `flutter analyze`-Warnungen**: `buildQuery`-experimentelle-API-Nutzung in `routine_provider.dart:17`, `practice_provider.dart:46,76`, `stats_provider.dart:29,38` — unkritisch, aber zu beobachten.

---

## 2. Datenmodell für Übungen heute

Zwei nur lose verbundene Modelle, faktisch aber ein einziger Übungstyp:

**`Rudiment`** (`features/lessons/models/rudiment.dart:63-101`) — der tatsächlich genutzte Übungstyp:

```dart
class Rudiment {
  final String id;
  final String name;
  final String category;        // freier String, kein Enum — flacher Kategoriebaum
  final String description;
  final int minBpm;
  final int targetBpm;
  final Difficulty difficulty;  // enum: beginner/intermediate/advanced/professional
  final List<StrokeBeat> sticking;
  final NoteGrid gridUnit;      // quarter/eighth/triplet/sixteenth
  final int beatsPerBar;
  final List<TechniqueSection> technique;
  final String? svgAssetPath;
  final int? level;             // Ordering für die "Übungen"-Praxisplan-Spur
}
```

`StrokeBeat` (`rudiment.dart:33-55`) trägt `hand` (R/L), `isAccent`, `isGhost`, `isRest`, `graces: List<Hand>` (Flam/Drag-Vorschläge) — ein pro-Note-Modell, das dem Brief-Zielbild eines neutralen Score-Modells näher ist als angenommen (es ist **kein** simpler String wie `'RLRL RLRL'`, sondern eine typisierte Objektliste).

**Kategorisierung ist ein flacher Kategoriebaum, keine Tag-Achsen.** `category` ist ein einzelner freier String (`rudiments_seed.dart:1860-1868`: `rudimentCategories = ['Rolls','Paradiddles','Flams','Ruffs','Ghost Notes','Linear Patterns','Marching Snare', ...]`), plus eine disjunkte Zweitliste `exerciseCategories` (`'Geschwindigkeit','Stockkontrolle','Ausdauer','Akzente','Dynamik & Ghost Notes','Timing & Gleichmäßigkeit'`) für den geführten "Übungen"-Plan. Ein Rudiment gehört zu genau einer Kategorie — kein Mehrachsen-Tagsystem irgendwo im Code (grep auf `tags`, `voicing`, `source:`, `generated|authored|excerpt` — keine Treffer in `lib/`).

**Speicherung**: Übungen sind einkompilierte Konstanten — nicht persistiert, nicht nutzerbearbeitbar, nicht nach Achsen abfragbar. Ein hartcodierter Katalog, genau der "Notendateien als Assets"-Ansatz, von dem der Brief wegwill.

**Planung/Scheduling**: zwei unabhängige Spuren —
1. `practicePlanProvider` (`lessons_provider.dart:31-42`) — statische, lineare Ordnung nach `level` dann `difficulty`; nicht adaptiv.
2. `dailyRoutineProvider` (`features/learning/routine_provider.dart:12-73`) — der eigentliche adaptive Scheduler, siehe Abschnitt 3.

Es gibt genau **einen** `Exercise`-artigen Typ (`Rudiment`), keine `source`/`voicing`-Felder, kein Zeiger-/Excerpt-Konzept, keinen Generator im Sinne des Briefs — alle zentralen Säulen des Zieldatenmodells sind Neuland.

---

## 3. Existierende Wiederholungs-/Lernlogik

Ja — ein vereinfachtes SM-2-artiges Spaced-Repetition-System plus eine separate BPM-Progressionsleiter. Beide sind pures Dart, unit-getestet, bewusst von Flutter entkoppelt.

- **`SpacedRepetitionService`** (`features/learning/spaced_repetition_service.dart:3-28`): `updateAfterSession(RudimentProgress, int rating)`. Feste Intervall-Leiter `[1,3,7,14,30,60]` Tage. Rating 1 → Reset auf Intervall 1; Rating 2 → Intervall unverändert; Rating 3 → reps++ und eine Stufe hoch.
- **`BpmProgressionService`** (`features/learning/bpm_progression_service.dart:3-35`): `nextSuggestedBpm(...)` → +5/+2/+0 BPM je nach Rating, geklemmt auf `targetBpm`. Leitet zusätzlich `MasteryLevel` aus `bestBpm/targetBpm` ab.
- **Verdrahtung**: `PracticeNotifier.saveSession` (`features/practice/practice_provider.dart:16-70`) ist die einzige Aufrufstelle — schreibt `PracticeSession` nach Isar, lädt/erstellt `RudimentProgress`, ruft beide Services auf, persistiert das Ergebnis zurück.
- **Tagesplanung**: `dailyRoutineProvider` (`routine_provider.dart:12-73`) generiert daraus einen Plan — Priorität: (1) überfällige Reviews, (2) aktive nicht-fällige Rudiments, (3) ein neues Rudiment niedrigster Schwierigkeit. Gedeckelt auf 5 Einträge.

**Abhängigkeit vom Übungstyp**: Die Lernlogik ist rein über `String rudimentId` (`RudimentProgress.rudimentId`, `@Index(unique: true)`) verknüpft und sonst generisch — sie greift nicht auf `Rudiment`-Felder zu außer `targetBpm` (von außen übergeben) und `difficulty` (nur für Neu-Rudiment-Ordering). **Das ist eine gute Nachricht für den Brief**: Die SM-2/BPM-Logik ist bereits ID-verknüpft und herkunftsunabhängig — sie sollte sauber an ein vereinheitlichtes `Exercise.id` andocken, unabhängig von `source`. Der einzige Kopplungspunkt ist `RudimentProgress.rudimentId` als reiner String ohne referenzielle Integrität — ein Austausch des Katalogs darunter bricht sie nicht, aber nichts validiert aktuell, dass eine `rudimentId` noch auf eine reale Übung zeigt.

**Scope-Hinweis aus `BERICHT_TRAINING_PROGRAM.md`**: Ein *zweiter*, strukturell anderer Generator (`TrainingProgram`/`ProgramPhase`/`ProgramDay`/`ExerciseBlock`, Isar-Collection-basiertes 12-Wochen-Programm) war in `BRIEF_TRAINING_PROGRAM.md`/`STICK_CONTROL_PROGRAM.md` geplant, aber **nie implementiert** (grep auf diese Klassennamen — keine Treffer). Kein aktueller Konflikt, aber die *Absicht*, ein zweites paralleles Generator-System zu bauen, sollte bei der Abstimmung mit diesem Brief berücksichtigt werden — der Brief warnt explizit vor "drei parallelen Systemen".

---

## 4. Welche Plattformen sind heute gebaut?

Plattform-Ordner existieren für `android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/` (Standard-`flutter create`-Scaffolds).

- **Android**: Einzige Plattform mit echter Anpassung. `applicationId = "com.example.drum_coach"` ist noch die **Template-Default-ID** — ungeeignet für einen Play-Store-Release. Manifest deklariert `RECORD_AUDIO`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`. `docs/CLAUDE.md` sagt explizit: "Android-first. iOS support may follow later."
- **iOS**: Scaffold vorhanden, aber `Info.plist` hat **keinen `NSMicrophoneUsageDescription`-Key** — die Mic-Aufnahme (Phase-8-Coaching) würde zur Laufzeit crashen/stumm verweigert werden. Keine Hinweise auf jemals erfolgten Testlauf.
- **Desktop (macOS/Linux/Windows)**: Scaffolds vorhanden, `flutter analyze`/`test` laufen sauber durch, aber macOS-Entitlements erlauben nur `app-sandbox`, `cs.allow-jit`, `network.server` — **kein Mikrofon-Entitlement, kein `network.client`** (ausgehende Netzwerkaufrufe für die Claude-API würden im Sandbox-Build vermutlich blockiert). Keine CI, keine Build-Artefakte, kein Hinweis auf tatsächlichen End-to-End-Testlauf auf einer der drei Desktop-Plattformen.
- **Web**: Scaffold vorhanden, aber `isar_flutter_libs` (native Binärladung) und `record`/`flutter_soloud` funktionieren ohne Zusatzarbeit vermutlich nicht im Web. `docs/CLAUDE.md` erwähnt Web nirgends als Ziel — vermutlich ungenutztes Scaffold-Überbleibsel.

**Fazit**: Nur Android ist ein reales, funktionierendes, getestetes Ziel. iOS/macOS/Windows/Linux/Web sind unkonfigurierte Scaffolds mit fehlenden Permission-/Entitlement-Deklarationen für bereits gebaute Features (Mikrofon, Netzwerk). Die Brief-Anforderung "Android, iOS und Desktop" ist eine echte Lücke — Permission-Plumbing muss vor den Phase-8-Features (Mic-Coaching) auf jeder Nicht-Android-Plattform nachgezogen werden, unabhängig vom Notation/Song-Sync-Umbau.

---

## 5. Was kollidiert mit dem Zielbild — konkret

**a) Vereinheitlichtes `Exercise` mit `source`/`voicing`.**
Kollidiert direkt mit `Rudiment` (`rudiment.dart:63-101`). Betroffene Konsumenten: `lessons_provider.dart` (alle 4 Provider), `lessons_screen.dart`, `lesson_detail_screen.dart`, `practice_session_screen.dart`, `routine_provider.dart:14,28,57`, `coaching/exercise_generator_screen.dart:149-161` (baut bereits ad-hoc ein `Rudiment` aus generierten `StrokeBeat`s — de facto schon eine "generated"-Übung, nur nicht so modelliert), `shared/widgets/notation_staff_widget.dart:11` (nimmt `Rudiment` direkt entgegen). `RudimentProgress.rudimentId` und `PracticeSession.rudimentId` sind lose gekoppelte String-FKs ohne Schema-Bindung — günstig für eine Migration, da IDs stabil bleiben können (kein Datenverlust-Risiko für bestehende `RudimentProgress`/`PracticeSession`-Einträge).

**b) Tags als Achsen statt Kategoriebaum.**
Kollidiert mit `category: String` (`rudiment.dart:66`) und den zwei flachen Kategorielisten in `rudiments_seed.dart:1851-1868`. `groupedRudimentsProvider` (`lessons_provider.dart:11-18`) und die darauf gebaute `LessonsScreen`-UI setzen eine Kategorie pro Übung voraus. Umstellung auf Mehrachsen-Tags ist echte Datenmigration: alle ~46 Seed-Einträge müssten neu getaggt werden, da kein bestehendes Feld sauber auf die sechs vorgeschlagenen Achsen mappt.

**c) Notation/Generator/Renderer-Trennung (neutrales Score-Modell, austauschbarer Renderer, alphaTab-Vorschlag).**
Keine Renderer-Abstraktion existiert. `NotationStaffWidget` (`shared/widgets/notation_staff_widget.dart:10-41`) ist ein handgeschriebener `CustomPainter`, der `Rudiment` direkt entgegennimmt (kein neutrales Score-Modell) und eine feste einzeilige Fünf-Linien-Notation zeichnet — funktioniert, ist getestet (`test/notation_staff_test.dart`), aber weder neutral noch austauschbar noch kit-fähig (einstimmig by design). Kein `alphaTab`, `webview`, `musicxml`, `guitarpro` irgendwo im Projekt (grep, null Treffer) — vollständig Neuland. **Empfehlung zur Prüfung**: den bestehenden CustomPaint-Renderer als leichten Pad-Modus-Renderer behalten (erfüllt "einzeilige Notation ... vollständig offline" schon fast wörtlich), alphaTab nur für den Kit-Modus (volle Kit-Notation, Song-Wiedergabe) einführen — Doppel-Renderer statt Wegwerfen des funktionierenden Codes.

**d) Excerpt als Zeiger in einen importierten Score.**
Keine Import-Pipeline, keine Score-Speicherung, kein `bar_from/bar_to/track_index`-Konzept (grep `excerpt` — null Treffer außer im Brief selbst). Vollständig Neuland, kein Konflikt, aber auch nichts zum Andocken.

**e) SyncMap mit Ankerpunkten für echtes Audio/Video.**
Kein YouTube-Embed, kein Anker-/Tap-Along-Konzept, kein Medien-Sync-Code (grep `youtube|syncmap|anchor|tap.?along` — null Treffer). Kein Video-/YouTube-Player-Package in `pubspec.yaml`. Vollständig Neuland.

**f) Modi statt Kategorien (Speed/Weak-Hand/Chops/Loop).**
Teilkollision: Heute ist "Geschwindigkeit" (Speed) selbst eine *Kategorie* mit eigenen `Rudiment`-Einträgen (`rudiments_seed.dart:1852`) — genau das "Modi verdoppeln den Bestand"-Antimuster, vor dem der Brief warnt. Umstellung von Speed/Chops von Kategorie-mit-eigenem-Inhalt zu zustandslosem Modifikator ist ein echter Designwechsel, betrifft `practicePlanProvider`s Sortierschlüssel (`level`-basiert) und die UI, die "Geschwindigkeit" als eigene Liste zeigt.

**g) Pad- vs. Kit-Modus.**
Kein `voicing`-Feld, kein Doppel-Renderer-Schalter — heute existiert genau ein Darstellungsmodus, überall identisch genutzt. Die App ist implizit bereits "Pad-Modus-förmig" (einzeilig, Klick/Rim/Snare-Sounds prozedural generiert via `MetronomeEngine`, `features/metronome/metronome_engine.dart:230-278` — kein gesampeltes Kit, keine Spuren) — brauchbarer Startpunkt für Pad-Modus, aber Kit-Modus (volle Kit-Notation, Spursteuerung) hat keinerlei Grundgerüst.

**h) "Keine stillen Parallelsysteme" — Beobachtung, kein direkter Codekonflikt.**
Das Coaching-Feature (`exercise_generator_screen.dart` + `ai_coaching_service.dart`) implementiert bereits einen Freitext-zu-`List<StrokeBeat>`-**Generator** über die Claude-API — ein anderer Generator-Typ als der im Brief vorgeschlagene parametrische Sticking-Grammatik-Generator. Der Brief-Abschnitt "Übungen: generieren statt katalogisieren" erwähnt oder klärt das Verhältnis zu diesem bereits gebauten Feature nicht. **Offene Frage an den Brief-Autor**: Bleibt der KI-Freitext-Generator als separates, komplementäres Feature bestehen, oder wird er durch/auf den neuen Grammatik-Generator abgelöst/aufgebaut?

---

## 6. Migrationsvorschlag

**Behalten (geringes Risiko, kein Brief-Konflikt):**
- `SpacedRepetitionService`, `BpmProgressionService` — generisch, ID-verknüpft, gut getestet. Der Brief will explizit genau das ("bestehende SM-2/Gate-Logik hängt hier"). Höchstens FK-Umbenennung nötig.
- `MetronomeEngine` — Isolate-basiert, driftfrei, manuell getestet. Beide Briefs (Training-Program und dieser) sagen explizit "Metronom nicht anfassen". Wiederverwenden für Klick/Count-in im synthetischen Wiedergabepfad.
- Isar/`shared_preferences` als lokale Persistenz — kein Grund zum Austausch, "Offline-first" ist auch hier Anforderung.
- `PracticeSession`-Konzept (Session-Logging) — Form behalten, nur FK umhängen.

**Erweitern (mittleres Risiko, additiv):**
- `Rudiment`/`StrokeBeat` → zum Spezialfall "einstimmig" des neutralen Score-Modells weiterentwickeln, statt verwerfen. `StrokeBeat`s Accent/Ghost/Rest/Graces-Felder sind ein brauchbares Note-Primitiv für ein reicheres Score-IR. Risiko: mittel — betrifft jeden Screen, der ein `Rudiment` rendert.
- `RudimentProgress`/`PracticeSession.rudimentId` → umbenennen/umhängen auf `exerciseId`, verweisend auf das neue `Exercise.id`. Risiko: niedrig-mittel — keine Schema-Migration nötig, wenn IDs beim `Rudiment → Exercise`-Umbau stabil bleiben.
- `NotationStaffWidget` → als Pad-Modus-Renderer behalten, aber hinter das geforderte Renderer-Interface stellen statt `Rudiment` direkt zu konsumieren. Risiko: mittel — Interface muss zuerst entworfen werden.

**Ersetzen (höheres Risiko, echte Neubauten):**
- `category: String` + Kategorielisten → Tag-Achsen. Risiko hoch für die Daten (46 Einträge neu taggen), niedrig für die Architektur (nur `groupedRudimentsProvider` als echter Konsument).
- Hartcodierter Seed-Katalog (`rudiments_seed.dart`, 1869 Zeilen) → Generator + kleiner handnotierter Bestand. Risiko hoch — der größte Engineering-Aufwand im Brief. Empfehlung: Generator zunächst `Rudiment`/`StrokeBeat`-förmigen Output erzeugen lassen, damit Renderer/Lernlogik unverändert bleiben, bevor das Typsystem angefasst wird.
- Kit-Modus-Rendering / alphaTab-Integration. Risiko hoch — externe Abhängigkeit, laut Brief selbst erst in Phase 0 zu bewerten (siehe Abschnitt "Notation & Wiedergabe" im Brief). Erst nach stabilem Pad-Modus und stehendem Renderer-Interface angehen, isoliert und revertierbar.
- Song-Import / Excerpt-Zeiger / SyncMap. Risiko hoch, aber isoliert — neue Subsysteme ohne Bestandskonflikt, können spät/parallel gebaut werden, ohne den Übungs-/Lernkern zu destabilisieren — deckt sich mit der Schrittfolge im Brief (Schritte 8–9).

**Vorgeschlagene Reihenfolge** (bestätigt im Wesentlichen die Brief-eigene Sequenz, abgeglichen mit dem tatsächlichen Bestand):

1. `Exercise`-Typ vereinheitlichen (erweitern statt ersetzen), `source`/`voicing` ergänzen, `RudimentProgress`/`PracticeSession`-FKs umhängen. Niedrig-mittleres Risiko, mechanisch, per bestehender Testsuite als Regressionsnetz absicherbar.
2. Kategorie → Tag-Achsen, `groupedRudimentsProvider` umschreiben, Seed-Daten neu taggen. Mittleres Risiko, überwiegend Datenarbeit; Entscheidung nötig, ob `practicePlanProvider`s `level`-Ordering als "kuratierte Spur" neben Tags weiterlebt.
3. Renderer-Interface definieren, `NotationStaffWidget` dahinter anpassen. Mittleres Risiko, begrenzt auf `lib/shared/widgets/` und die drei aktuellen Aufrufstellen.
4. Sticking-Grammatik-Generator bauen, der ins bestehende `StrokeBeat`/Score-Format ausgibt. Hoher Aufwand, mittel-niedriges Integrationsrisiko, da der Output in bereits funktionierendes Rendering/Lernlogik einschnappt.
5. Die zwei bestehenden Generatoren (Tages-Routine-Picker vs. neuer Grammatik-Generator vs. bereits gebauter KI-Freitext-Generator) abgleichen — **braucht eine Produktentscheidung vor weiterem Code**, siehe offene Frage in Abschnitt 5h. Empfehlung: an den Brief-Autor zurückspielen statt zu raten, gemäß Briefs eigener Maxime "Erst fragen, dann bauen".
6. Kit-Modus + alphaTab-Bewertung/-Integration. Hohes Risiko, isoliert hinter dem Interface aus Schritt 3.
7. Song-Import + Excerpt-Zeiger, dann SyncMap/Tap-Along. Hohes Risiko, aber isoliert, sicherheitshalber zuletzt.
8. Plattform-Härtung (iOS-Mic-Entitlement, macOS-Entitlements für Mic + ausgehendes Netzwerk, echte Android-`applicationId`, Desktop-Build-Verifikation). Niedriges Risiko, hohe Dringlichkeit — sollte parallel/früh laufen, da diese Lücken (fehlender `NSMicrophoneUsageDescription`, fehlende macOS-`network.client`/Audio-Entitlements, `com.example.drum_coach`) bereits bestehende Bugs sind, unabhängig vom Umbau.

**Offene Frage, die eine Antwort vom Brief-Autor braucht, kein Rateergebnis**: Was passiert mit dem bereits gebauten Phase-8-KI-Freitext-Generator (`exercise_generator_screen.dart` + `AICoachingService.generateExercise`), sobald der parametrische Sticking-Grammatik-Generator existiert? Beide erzeugen aktuell dieselbe Ausgabeform (`List<StrokeBeat>`) über komplett unterschiedliche Mechanismen (LLM-Aufruf vs. Grammatik) — der Brief klärt das Verhältnis nicht.

---

## Zusammenfassung für die Freigabeentscheidung

- Die bestehende Lernlogik (SM-2, BPM-Progression, Tagesplanung) ist bereits generisch genug, um unter dem neuen `Exercise`-Modell weiterzuleben — **kein Wegwerfen nötig**.
- Der bestehende Notation-Renderer ist ein brauchbarer Startpunkt für den Pad-Modus, nicht Bestandsschrott.
- Der größte Umbau ist nicht technische Migration, sondern der neue Generator (Schritt 4) und die Kategorie→Tag-Migration (Schritt 2) — beide sind primär Neubau/Datenarbeit, kein Ersetzen von funktionierendem Code.
- Zwei offene Produktfragen sollten vor Baubeginn geklärt werden: (1) Verhältnis KI-Freitext-Generator vs. Grammatik-Generator (Abschnitt 5h/6), (2) Verhältnis `practicePlanProvider`s kuratierter Spur zu tag-basierter Organisation (Abschnitt 6, Schritt 2).
- Plattform-Lücken (iOS/macOS-Permissions, Android-`applicationId`) sind unabhängig vom Brief bereits vorhandene Bugs und sollten früh mit angegangen werden, da sie sonst jeden Multi-Plattform-Test blockieren.
