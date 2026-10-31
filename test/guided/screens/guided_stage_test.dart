import 'package:drum_coach/features/guided/widgets/guided_stage.dart';
import 'package:drum_coach/features/practice/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Size size, {String? photo, Widget? child}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: GuidedStage(
            photo: photo ?? practiceBackdrops.first,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );

Future<void> _pump(WidgetTester tester, Size size,
    {String? photo, Widget? child}) async {
  tester.view.physicalSize = const Size(2560, 1440);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_host(size, photo: photo, child: child));
}

void main() {
  testWidgets('stage photo is 4:3 at full height when wide', (tester) async {
    await _pump(tester, const Size(2560, 790));
    final size = tester.getSize(find.byKey(const ValueKey('stage-photo')));
    expect(size.height, 790);
    expect(size.width, closeTo(1053.33, 0.5));
  });

  testWidgets('stage photo takes full width when the stage is narrow',
      (tester) async {
    await _pump(tester, const Size(400, 790));
    final size = tester.getSize(find.byKey(const ValueKey('stage-photo')));
    expect(size.width, 400);
    expect(size.height, 790);
  });

  testWidgets('blurred copy fills the stage', (tester) async {
    await _pump(tester, const Size(2560, 790));
    expect(tester.getSize(find.byKey(const ValueKey('stage-blur'))),
        const Size(2560, 790));
  });

  testWidgets('missing photo still renders the stage', (tester) async {
    await _pump(tester, const Size(2560, 790),
        photo: 'assets/does_not_exist.jpg', child: const Text('overlay'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('overlay'), findsOneWidget);
  });

  test('focus table default is -0.2', () {
    expect(backdropFocusY('assets/unknown.jpg'), -0.2);
  });

  test('every practiceBackdrops entry has a focus value in -1..1', () {
    for (final p in practiceBackdrops) {
      expect(backdropFocus.containsKey(p), isTrue, reason: p);
      expect(backdropFocus[p]!, inInclusiveRange(-1.0, 1.0), reason: p);
    }
  });
}
