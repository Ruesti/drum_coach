import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/shared/widgets/notation_staff_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  const ids = [
    'groove_rock8',
    'groove_rock16',
    'groove_halftime',
    'groove_shuffle',
    'groove_swing',
    'groove_funk16',
    'set_fill_sixteenth_singles',
    'set_fill_paradiddle',
    'set_fill_triplets',
    'feet_double_bass_sixteenths',
    'feet_kick_control',
    'feet_double_bass_triplets',
  ];

  for (final id in ids) {
    testWidgets('golden: PATTERN bar of $id', (tester) async {
      final r = rudimentsSeedData.firstWhere((r) => r.id == id);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: 360, child: NotationStaffWidget(rudiment: r)))));
      expect(tester.takeException(), isNull);
      await expectLater(find.byType(NotationStaffWidget),
          matchesGoldenFile('goldens/kit_pattern_$id.png'));
    });
  }

  testWidgets('golden: the whole Rock 8ths sheet', (tester) async {
    tester.view.physicalSize = const Size(360, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final r = rudimentsSeedData.firstWhere((r) => r.id == 'groove_rock8');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 360, child: SheetStaffWidget(rudiment: r))))));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(SheetStaffWidget),
        matchesGoldenFile('goldens/kit_sheet_groove_rock8.png'));
  });

  testWidgets('golden: the whole Double Bass Eighths sheet', (tester) async {
    tester.view.physicalSize = const Size(360, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final r =
        rudimentsSeedData.firstWhere((r) => r.id == 'feet_double_bass_eighths');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    width: 360, child: SheetStaffWidget(rudiment: r))))));
    expect(tester.takeException(), isNull);
    await expectLater(find.byType(SheetStaffWidget),
        matchesGoldenFile('goldens/kit_sheet_feet_double_bass_eighths.png'));
  });
}
