import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/models/session_log.dart';
import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/coaching/services/unassigned_metrics.dart';
import 'package:drum_coach/features/practice/analysis_announcement.dart';
import 'package:drum_coach/features/practice/widgets/result_sheet.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });
  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  final analysis = SessionAnalysis(
    alignment: const AlignmentSummary(
        expectedCount: 32,
        hitCount: 30,
        missedCount: 2,
        extraCount: 0,
        handValuesAllowed: true,
        jitterLimitExceeded: false,
        lapses: []),
    unassigned: const UnassignedMetrics(
        timingMedianMs: -3,
        timingSpreadMs: 11,
        intervalSpreadMs: 9,
        dynamicsSpread: null,
        playedCount: 30,
        expectedCount: 32),
    timing: const TimingAnalysis(
        overallDeviationMs: 3,
        rightHandDeviationMs: 2,
        leftHandDeviationMs: 5,
        jitterMs: 9),
    detectedHits: 30,
    expectedHits: 32,
  );

  Future<({List<int> rated, List<int> done, List<int> exported})> pump(
    WidgetTester tester, {
    SessionAnalysis? a,
    Announcement? announcement,
    SessionLog? log,
    bool coach = false,
  }) async {
    final rated = <int>[];
    final done = <int>[];
    final exported = <int>[];
    await tester.pumpWidget(MaterialApp(
      theme: drumCoachTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResultSheet(
            rudimentName: 'Single Paradiddle',
            bpm: 84,
            durationSeconds: 480,
            analysisMode: true,
            analysis: a,
            announcement: announcement,
            ladderResult: ValueNotifier<String?>(null),
            sessionLog: ValueNotifier<SessionLog?>(log),
            coachFeedback: ValueNotifier<String?>(null),
            coachLoading: ValueNotifier<bool>(false),
            coachEnabled: coach,
            onRate: rated.add,
            onDone: () => done.add(1),
            onExport: () => exported.add(1),
          ),
        ),
      ),
    ));
    await tester.pump();
    return (rated: rated, done: done, exported: exported);
  }

  FilledButton doneButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Done'));

  testWidgets('header, banner and core values', (tester) async {
    await pump(tester,
        a: analysis,
        announcement: const Announcement('Clean run — hand analysis below.',
            positive: true));
    expect(find.text('SESSION COMPLETE'), findsOneWidget);
    expect(find.text('Single Paradiddle'), findsOneWidget);
    expect(find.text('84 BPM · 8:00 · analysis'), findsOneWidget);
    expect(find.text('Clean run — hand analysis below.'), findsOneWidget);
    expect(find.text('You miss 2 notes'), findsOneWidget);
    expect(find.text('30 of 32 hit · 94 %'), findsOneWidget);
    expect(find.text("You're right on the click"), findsOneWidget);
    expect(find.text('Your hands are even'), findsOneWidget);
    expect(find.text('No mic analysis this time'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rating chips: Done is disabled until a chip is tapped',
      (tester) async {
    final r = await pump(tester, a: analysis);
    expect(find.text('HOW DID IT FEEL?'), findsOneWidget);
    for (final t in [
      'Struggled',
      'OK',
      'Solid',
      'same BPM',
      '+2 BPM',
      '+5 BPM'
    ]) {
      expect(find.text(t), findsOneWidget);
    }
    expect(doneButton(tester).onPressed, isNull);

    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(r.rated, [2]);
    expect(doneButton(tester).onPressed, isNotNull);

    // A second tap changes nothing: the session is saved once.
    await tester.tap(find.text('Solid'));
    await tester.pump();
    expect(r.rated, [2]);

    await tester.tap(find.text('Done'));
    await tester.pump();
    expect(r.done.length, 1);
  });

  testWidgets('without analysis: calm line, no details, no banner',
      (tester) async {
    await pump(tester);
    expect(find.text('No mic analysis this time'), findsOneWidget);
    expect(find.text('Measurement details'), findsNothing);
    expect(find.byType(VerdictBanner), findsNothing);
  });

  testWidgets('details are closed and open on tap', (tester) async {
    await pump(tester, a: analysis);
    expect(find.text('Timing vs click'), findsNothing);
    await tester.tap(find.text('Measurement details'));
    await tester.pumpAndSettle();
    expect(find.text('Timing vs click'), findsOneWidget);
    expect(find.text('Matched / missed / extra'), findsOneWidget);
    expect(find.text('R hand'), findsOneWidget);
  });

  testWidgets('export only with a session log', (tester) async {
    await pump(tester, a: analysis);
    expect(find.text('Export session (JSONL)'), findsNothing);
    final r = await pump(tester, a: analysis, log: SessionLog());
    expect(find.text('Export session (JSONL)'), findsOneWidget);
    await tester.tap(find.text('Export session (JSONL)'));
    expect(r.exported.length, 1);
  });

  testWidgets('ladder result appears once the notifier delivers it',
      (tester) async {
    final ladder = ValueNotifier<String?>(null);
    await tester.pumpWidget(MaterialApp(
      theme: drumCoachTheme,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResultSheet(
            rudimentName: 'Single Paradiddle',
            bpm: 84,
            durationSeconds: 480,
            analysisMode: true,
            analysis: analysis,
            announcement: null,
            ladderResult: ladder,
            sessionLog: ValueNotifier<SessionLog?>(null),
            coachFeedback: ValueNotifier<String?>(null),
            coachLoading: ValueNotifier<bool>(false),
            coachEnabled: false,
            onRate: (_) {},
            onDone: () {},
            onExport: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.textContaining('Clean tempo'), findsNothing);
    ladder.value = 'Clean tempo now 88 BPM.';
    await tester.pump();
    expect(find.text('Clean tempo now 88 BPM.'), findsOneWidget);
  });
}
