import 'package:drum_coach/features/practice/practice_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('space toggles, arrows bump, shift bumps by 5, esc leaves',
      (t) async {
    var toggles = 0, left = 0;
    final bumps = <int>[];
    await t.pumpWidget(MaterialApp(
      home: CallbackShortcuts(
        bindings: practiceShortcuts(
          toggle: () => toggles++,
          bumpBpm: bumps.add,
          leave: () => left++,
        ),
        child: const Focus(autofocus: true, child: SizedBox.expand()),
      ),
    ));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(toggles, 1);
    expect(bumps, [1, -1, 5]);
    expect(left, 1);
  });
}
