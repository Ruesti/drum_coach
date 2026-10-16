import 'package:drum_coach/features/settings/sequence_repeats_row.dart';
import 'package:drum_coach/shared/widgets/app_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chips 1× to 4×, the value selected, a tap reports its count',
      (tester) async {
    final changes = <int>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SequenceRepeatsRow(value: 2, onChanged: changes.add))));
    AppSelectableChip chip(int n) =>
        tester.widget<AppSelectableChip>(find.byKey(ValueKey('repeats-$n')));
    expect(
        [for (var n = 1; n <= 4; n++) chip(n).label], ['1×', '2×', '3×', '4×']);
    expect([for (var n = 1; n <= 4; n++) chip(n).selected],
        [false, true, false, false]);
    await tester.tap(find.byKey(const ValueKey('repeats-3')));
    expect(changes, [3]);
  });
}
