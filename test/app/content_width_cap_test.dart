import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDesktopOverride = null);

  testWidgets('desktop: content is centered and capped at 900', (t) async {
    debugDesktopOverride = true;
    await t.binding.setSurfaceSize(const Size(1400, 800));
    await t.pumpWidget(MaterialApp(
      builder: capContentWidth,
      home: const SizedBox.expand(key: Key('content')),
    ));
    expect(t.getSize(find.byKey(const Key('content'))).width, 900);
  });

  testWidgets('mobile: content fills the width', (t) async {
    debugDesktopOverride = false;
    await t.binding.setSurfaceSize(const Size(1400, 800));
    await t.pumpWidget(MaterialApp(
      builder: capContentWidth,
      home: const SizedBox.expand(key: Key('content')),
    ));
    expect(t.getSize(find.byKey(const Key('content'))).width, 1400);
  });
}
