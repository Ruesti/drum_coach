import 'package:drum_coach/app/theme.dart';
import 'package:drum_coach/features/practice/widgets/tempo_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, int bpm, ValueChanged<int> onChanged) {
    return tester.pumpWidget(MaterialApp(
      theme: drumCoachPracticeTheme,
      home: Scaffold(body: TempoRow(bpm: bpm, onChanged: onChanged)),
    ));
  }

  testWidgets('shows the tempo and steps by 4 BPM', (tester) async {
    int? changed;
    await pump(tester, 60, (v) => changed = v);
    expect(find.text('60'), findsOneWidget);
    expect(find.text('BPM'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    expect(changed, 64);
    await tester.tap(find.byIcon(Icons.remove));
    expect(changed, 56);
  });

  testWidgets('clamps at 40 and 240', (tester) async {
    int? changed;
    await pump(tester, 238, (v) => changed = v);
    await tester.tap(find.byIcon(Icons.add));
    expect(changed, 240);

    await pump(tester, 41, (v) => changed = v);
    await tester.tap(find.byIcon(Icons.remove));
    expect(changed, 40);
  });

  testWidgets('tapping the number opens the exact-entry dialog',
      (tester) async {
    await pump(tester, 84, (_) {});
    await tester.tap(find.text('84'));
    await tester.pumpAndSettle();
    expect(find.text('Enter BPM'), findsOneWidget);
  });
}
