import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/data/local/models/session_log.dart';
import 'package:drum_coach/features/coaching/models/session_analysis.dart';
import 'package:drum_coach/features/practice/analysis_announcement.dart';
import 'package:drum_coach/features/practice/widgets/result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Not a regression gate — a preview: renders the sheet with example values
/// so the look can be judged without a mic session (the emulator has none).
/// Regenerate with
/// `flutter test --update-goldens test/features/practice/result_sheet_golden_test.dart`.
void main() {
  testWidgets('result sheet preview', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // Taller than a phone on purpose: the preview shows the whole sheet at
    // once (in the app it scrolls inside the bottom sheet).
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2760);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
    addTearDown(() {
      binding.platformDispatcher.views.first.resetPhysicalSize();
      binding.platformDispatcher.views.first.resetDevicePixelRatio();
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
          timingMedianMs: -3.2,
          timingSpreadMs: 11.4,
          intervalSpreadMs: 9,
          dynamicsSpread: 0.18,
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
    await tester.pumpWidget(MaterialApp(
      theme: drumCoachTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF101010),
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: ResultSheet(
              rudimentName: 'Single Paradiddle',
              bpm: 84,
              durationSeconds: 480,
              analysisMode: true,
              analysis: analysis,
              announcement: const Announcement(
                  'Clean run — hand analysis below.',
                  positive: true),
              ladderResult: ValueNotifier<String?>('Clean tempo now 88 BPM.'),
              sessionLog: ValueNotifier<SessionLog?>(SessionLog()),
              coachFeedback: ValueNotifier<String?>(null),
              coachLoading: ValueNotifier<bool>(false),
              coachEnabled: false,
              onRate: (_) {},
              onDone: () {},
              onExport: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Solid'));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../../goldens/result_sheet_preview.png'));
  });
}
