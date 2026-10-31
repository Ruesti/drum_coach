import 'dart:io';

import 'package:drum_coach/app/design_tokens.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/coaching/services/stroke_analysis.dart';
import 'package:drum_coach/features/coaching/services/stroke_source.dart';
import 'package:drum_coach/features/coaching/services/mic_analysis_service.dart';
import 'package:drum_coach/features/lessons/data/rudiments_seed.dart';
import 'package:drum_coach/features/lessons/models/pattern_playback.dart';
import 'package:drum_coach/features/lessons/models/sheet_plan.dart';
import 'package:drum_coach/features/practice/widgets/line_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Speed Bursts line 4 is the first pad line with a whole-rest bar (`-1`):
/// it must lay out, play back and analyse like any other line.
void main() {
  setUpAll(() async {
    final bytes = await File('assets/fonts/Bravura.otf').readAsBytes();
    final loader = FontLoader('Bravura')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    AppTypography.label;
    await GoogleFonts.pendingFonts();
  });

  final bursts =
      rudimentsSeedData.firstWhere((r) => r.id == 'tech_speed_bursts');
  const line = 3; // line 4

  test('line 4 holds a whole-bar rest', () {
    final beats = bursts.sheet[line].beats;
    expect(beats.where((b) => b.isRest).length, greaterThanOrEqualTo(2));
  });

  testWidgets('LineView lays out the line with a whole-rest bar',
      (tester) async {
    for (final width in [360.0, 1200.0]) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SizedBox(
                  width: width,
                  height: 800,
                  child: Center(
                      child: LineView(
                          rudiment: bursts, line: line, activeTick: 0))))));
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  test('playback and stroke analysis handle the whole-rest bar', () {
    final plan = SheetPlan.sequence(bursts, [line], repeats: 1);
    final unit = bursts.withSticking(plan.beats);
    final pb = PatternPlayback.forRudiment(unit);
    // 4 bars of 4/4 at 24 ticks per quarter.
    expect(pb.totalTicks, 4 * 4 * 24);
    // The rest bars are silent.
    expect(pb.tickVolumes.sublist(96, 192).every((v) => v == 0), isTrue);

    // Simulate a mic run at 120 BPM exactly as the practice screen logs it.
    const t0 = 1700000000000.0;
    const msPerTick = 500 / 24;
    final log = <BeatRecord>[];
    final events = <StrokeEvent>[];
    for (var tick = 0; tick < pb.totalTicks; tick++) {
      if (!pb.isOnsetTick(tick)) continue;
      final idx = pb.noteIndexAtTick(tick);
      final ms = t0 + tick * msPerTick;
      log.add((
        beatIndex: idx,
        timestamp: DateTime.fromMicrosecondsSinceEpoch((ms * 1000).round()),
      ));
      if (!unit.sticking[idx].isRest) {
        events.add(StrokeEvent(
          timeMs: ms + 3,
          instrument: KitInstrument.pad,
          velocity: 0.6,
          rawNote: null,
          source: StrokeSourceKind.mic,
        ));
      }
    }
    final a = analyzeStrokes(
      events: events,
      beatLog: log,
      sticking: unit.sticking,
      source: StrokeSourceKind.mic,
    );
    expect(a.detectedHits, events.length);
  });
}
