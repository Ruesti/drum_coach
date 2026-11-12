import 'dart:async';

import 'package:drum_coach/audio/click_track.dart';
import 'package:drum_coach/content/exercises.dart';
import 'package:drum_coach/midi/stroke_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../run/fakes.dart';

import 'app_harness.dart';

Future<void> _openEntry(WidgetTester tester) async {
  await tester.tap(find.text('Entry exercise'));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

FilledButton _startButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.ancestor(of: find.text('Start'), matching: find.byType(FilledButton)));

void main() {
  testWidgets('run: finished run is saved and opens Feedback', (tester) async {
    // The auto-advancing clock runs the whole exercise at once.
    final store = await pumpApp(tester, clock: FakeClock());
    await _openEntry(tester);
    expect(find.text('Not calibrated — this run gets no gate verdict.'),
        findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(store.saved, hasLength(1));
    expect(store.saved.single.platform, 'test');
    expect(find.text('/mem/sessions/entry-test.jsonl'), findsOneWidget);
    expect(find.text('NOT MEASURABLE (no hits received)'), findsOneWidget);
  });

  testWidgets('run: device lost → run discarded, back to Home', (tester) async {
    final source = FakeSource();
    source.onStart = () async => source.conn.add(false);
    final store = await pumpApp(tester,
        clock: FakeClock(), open: (_, __) async => source);
    await _openEntry(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(
        find.text('MIDI device disconnected — run discarded'), findsOneWidget);
    expect(store.saved, isEmpty);
    expect(source.disposed, 1);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Basic Rock Beat'), findsOneWidget);
  });

  testWidgets(
      'run: leaving mid-run cancels it — the old run never stops the next '
      "run's click", (tester) async {
    final clock = ManualClock();
    final out = FakeOut(clock);
    final sources = <FakeSource>[];
    final store =
        await pumpApp(tester, clock: clock, out: out, sources: sources);
    final t0 = clock.now;
    // The click track of the entry exercise (count-in + 8 bars + tail).
    final runMs = renderClickTrack(
            bpm: entryExercise.bpm,
            bars: entryExercise.bars,
            beatsPerBar: entryExercise.beatsPerBar)
        .durationMs;

    await _openEntry(tester);
    await tester.tap(find.text('Start'));
    await _settle(tester);
    expect(find.text('Count-in'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(out.stopped, isTrue, reason: 'screen stops the click once');
    expect(sources[0].disposed, 1);

    clock.now = t0 + 10000;
    await _openEntry(tester);
    await tester.tap(find.text('Start'));
    await _settle(tester);
    expect(sources, hasLength(2));
    expect(out.stopped, isFalse);

    // Past the first run's end, inside the second one: wake both.
    clock.now = t0 + runMs + 1000;
    clock.release();
    await _settle(tester);
    expect(out.stopped, isFalse, reason: 'cancelled run left the click alone');
    expect(sources[0].stopped, isTrue);
    expect(sources[0].disposed, 1, reason: 'source disposed exactly once');
    expect(find.textContaining(RegExp(r'^Bar \d / 8$')), findsOneWidget);
    expect(store.saved, isEmpty);

    // Second run ends normally.
    clock.now = t0 + 10000 + runMs + 100;
    clock.release();
    await tester.pumpAndSettle();
    expect(out.stopped, isTrue);
    expect(store.saved, hasLength(1));
    expect(find.text('/mem/sessions/entry-test.jsonl'), findsOneWidget);
    expect(sources[1].disposed, 1);
  });

  testWidgets('run: Start is disabled while starting (no second source)',
      (tester) async {
    final pending = Completer<StrokeSource?>();
    var opened = 0;
    await pumpApp(tester, clock: FakeClock(), open: (_, __) {
      opened++;
      return pending.future;
    });
    await _openEntry(tester);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(_startButton(tester).onPressed, isNull);
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(opened, 1);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Could not open the MIDI device.'), findsOneWidget);
    expect(_startButton(tester).onPressed, isNotNull);
  });
}
