import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:drum_coach/features/metronome/metronome_engine.dart';
import 'package:drum_coach/features/metronome/metronome_provider.dart';
import 'package:drum_coach/features/settings/kit_learn_screen.dart';
import 'package:drum_coach/features/settings/midi_calibration_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/midi_fakes.dart';

/// Idle metronome without engine; counts start() calls.
class _CountingMetronome extends MetronomeNotifier {
  int starts = 0;
  @override
  MetronomeState build() => const MetronomeState(bpm: 72);
  @override
  void start() {
    starts++;
    super.start();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

  group('MidiCalibrationScreen', () {
    testWidgets(
        'double tap on Start starts once, quarters at 100 BPM; leaving '
        'restores the tempo', (t) async {
      final metronome = _CountingMetronome();
      final container = ProviderContainer(
          overrides: [metronomeNotifierProvider.overrideWith(() => metronome)]);
      addTearDown(container.dispose);
      container.read(metronomeNotifierProvider.notifier)
          .setSubdivision(Subdivision.eighth);
      final port = FakeMidiPort();
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            home: MidiCalibrationScreen(ports: FakeMidiPorts(port: port))),
      ));
      await t.pumpAndSettle();
      final start = find.text('Start');
      expect(start, findsOneWidget);
      final onPressed =
          t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start'))
              .onPressed!;
      onPressed();
      onPressed(); // second tap before the first one's await returned
      await t.pump();
      expect(metronome.starts, 1);
      final state = container.read(metronomeNotifierProvider);
      expect(state.bpm, 100);
      expect(state.subdivision, Subdivision.quarter);
      expect(state.isPlaying, isTrue);

      await t.pumpWidget(UncontrolledProviderScope(
          container: container, child: const SizedBox()));
      await t.pump();
      expect(container.read(metronomeNotifierProvider).bpm, 72);
      expect(container.read(metronomeNotifierProvider).isPlaying, isFalse);
      expect(port.closed, isTrue);
    });
  });

  group('KitLearnScreen', () {
    testWidgets('a failing device list shows the error instead of spinning',
        (t) async {
      await t.pumpWidget(MaterialApp(
          home: KitLearnScreen(
              ports: FakeMidiPorts(listError: StateError('plugin')))));
      await t.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Could not open the MIDI device.'), findsOneWidget);
    });

    testWidgets('a failing open shows the error instead of spinning',
        (t) async {
      await t.pumpWidget(MaterialApp(
          home: KitLearnScreen(
              ports: FakeMidiPorts(
                  port: FakeMidiPort(), openError: StateError('busy')))));
      await t.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Could not open the MIDI device.'), findsOneWidget);
    });

    testWidgets('several zones per instrument, then Next', (t) async {
      final port = FakeMidiPort();
      await t.pumpWidget(
          MaterialApp(home: KitLearnScreen(ports: FakeMidiPorts(port: port))));
      await t.pumpAndSettle();
      expect(find.text('Hit the Snare (all zones), then Next'), findsOneWidget);
      port.hit(38);
      await t.pump();
      port.hit(40);
      await t.pump();
      // Still on the snare: hits do not advance.
      expect(find.text('Hit the Snare (all zones), then Next'), findsOneWidget);
      expect(find.text('Notes for this instrument: 38, 40'), findsOneWidget);
      await t.tap(find.text('Next'));
      await t.pump();
      expect(find.text('Hit the Kick (all zones), then Next'), findsOneWidget);
      await t.tap(find.text('Save what I have so far'));
      await t.pumpAndSettle();
      expect(SettingsService.kitMappingFor('Fake Module')
          .notes[KitInstrument.snare], {38, 40});
    });
  });
}
