import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/features/guided/widgets/guided_backdrop.dart';
import 'package:drum_coach/features/guided/widgets/guided_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    debugDesktopOverride = null;
    uncappedContentCount.value = 0;
  });

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

  testWidgets('uncapped content without a route counts while mounted',
      (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Widget app(bool uncapped) => Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (c) => capContentWidth(
                c,
                uncapped
                    ? const UncappedContent(
                        child: SizedBox.expand(key: Key('box')))
                    : const SizedBox.expand(key: Key('box'))),
          ),
        );
    await t.pumpWidget(app(true));
    expect(t.getSize(find.byKey(const Key('box'))).width, 1280);
    expect(uncappedContentCount.value, 1);
    await t.pumpWidget(app(false));
    expect(t.getSize(find.byKey(const Key('box'))).width, 900);
    expect(uncappedContentCount.value, 0);
  });

  testWidgets('a route pushed on top of uncapped content caps again',
      (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(
      navigatorKey: nav,
      builder: capContentWidth,
      home: const UncappedContent(child: SizedBox.expand(key: Key('wide'))),
    ));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('wide'))).width, 1440);
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const SizedBox.expand(key: Key('top'))));
    await t.pump();
    // Capped from the first frame of the push (the new route is still
    // offstage in that frame).
    expect(
        t.getSize(find.byKey(const Key('top'), skipOffstage: false)).width,
        900);
    expect(t.getSize(find.byKey(const Key('wide'))).width, 900);
    await t.pumpAndSettle();
    expect(uncappedContentCount.value, 0);
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('wide'))).width, 1440);
    expect(uncappedContentCount.value, 1);
  });

  testWidgets('maxWidth: infinity lifts the cap to the whole window',
      (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(2560, 1440));
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
        maxWidth: double.infinity,
        child: SizedBox.expand(key: Key('full')),
      ),
    ));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('full'))).width, 2560);

    // A default (1440) route on top: its own limit applies.
    nav.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const UncappedContent(
        child: SizedBox.expand(key: Key('wide')),
      ),
    ));
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('wide'))).width, 1440);

    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('full'))).width, 2560);
    nav.currentState!.pop();
    await t.pumpAndSettle();
    expect(t.getSize(find.byKey(const Key('plain'))).width, 900);
    expect(uncappedContentCount.value, 0);
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
