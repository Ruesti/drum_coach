import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drum_coach/shared/widgets/bpm_control.dart';

void main() {
  group('BpmStepButtons', () {
    Future<int?> pumpAndTap(WidgetTester tester, String label, {int bpm = 100}) async {
      int? changedTo;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BpmStepButtons(
            bpm: bpm,
            onChanged: (v) => changedTo = v,
          ),
        ),
      ));
      await tester.tap(find.text(label));
      await tester.pump();
      return changedTo;
    }

    testWidgets('+5 adds 5 BPM', (tester) async {
      expect(await pumpAndTap(tester, '+5'), 105);
    });

    testWidgets('+1 adds 1 BPM', (tester) async {
      expect(await pumpAndTap(tester, '+1'), 101);
    });

    testWidgets('−1 subtracts 1 BPM', (tester) async {
      expect(await pumpAndTap(tester, '−1'), 99);
    });

    testWidgets('−5 subtracts 5 BPM', (tester) async {
      expect(await pumpAndTap(tester, '−5'), 95);
    });

    testWidgets('clamps at max', (tester) async {
      expect(await pumpAndTap(tester, '+5', bpm: 238), 240);
    });

    testWidgets('clamps at min', (tester) async {
      expect(await pumpAndTap(tester, '−5', bpm: 42), 40);
    });
  });

  group('editBpmDialog', () {
    testWidgets('returns the typed value clamped to range', (tester) async {
      int? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await editBpmDialog(context, current: 100);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, 240); // clamped to default max
    });

    testWidgets('returns null when cancelled', (tester) async {
      int? result = -1;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await editBpmDialog(context, current: 100);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
