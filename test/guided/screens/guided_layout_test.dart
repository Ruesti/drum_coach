import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/features/guided/widgets/guided_backdrop.dart';
import 'package:drum_coach/features/guided/widgets/guided_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDesktopOverride = null);

  test('guidedWide boundary', () {
    expect(guidedWide(999), isFalse);
    expect(guidedWide(1000), isTrue);
    expect(guidedMaxWidth, 1440);
  });

  testWidgets('uncapped content uses full width on desktop', (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      builder: capContentWidth,
      home: const SizedBox.expand(key: Key('plain')),
    ));
    expect(t.getSize(find.byKey(const Key('plain'))).width, 900);

    nav.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const UncappedContent(
        child: SizedBox.expand(key: Key('wide')),
      ),
    ));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('wide'))).width, 1280);

    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('plain'))).width, 900);
  });

  testWidgets('backdrop scrim switches with playing', (t) async {
    Future<List<Color>> colors(bool playing) async {
      await t.pumpWidget(MaterialApp(
        home: GuidedBackdrop(
          playing: playing,
          photo: 'assets/none.jpg',
          child: const SizedBox(),
        ),
      ));
      await t.pumpAndSettle();
      final box = t.widget<AnimatedContainer>(
          find.byKey(const ValueKey('guided-scrim')));
      return ((box.decoration! as BoxDecoration).gradient! as LinearGradient)
          .colors;
    }

    expect(await colors(false),
        const [Color(0x26101010), Color(0x66101010), Color(0xD9101010)]);
    expect(await colors(true),
        const [Color(0x4D101010), Color(0x99101010), Color(0xE0101010)]);
  });
}
