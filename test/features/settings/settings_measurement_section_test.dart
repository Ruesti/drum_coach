import 'dart:async';

import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/settings/measurement_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePorts implements MidiPortService {
  FakePorts(this.list);
  final List<({String id, String name, bool hasInput})> list;
  final setup = StreamController<void>.broadcast();
  @override
  Future<List<({String id, String name, bool hasInput})>> inputDevices() async =>
      list;
  @override
  Future<MidiPort?> open(String deviceId) async => null;
  @override
  Stream<void> get setupChanges => setup.stream;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    debugDesktopOverride = false;
  });
  tearDown(() => debugDesktopOverride = null);

  testWidgets('shows the four sources, saves the choice, lists the device',
      (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MeasurementSection(
          ports: FakePorts([(id: '20:0', name: 'Millenium', hasInput: true)]),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Mic'), findsOneWidget);
    expect(find.text('MIDI'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.textContaining('Millenium'), findsOneWidget);
    expect(find.textContaining('otherwise the microphone'), findsOneWidget);
    await t.tap(find.text('MIDI'));
    await t.pumpAndSettle();
    expect(SettingsService.measurementSource, MeasurementSource.midi);
  });

  testWidgets('no device: says so and still offers the learn step', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: MeasurementSection(ports: FakePorts(const []))),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('No MIDI device'), findsOneWidget);
    expect(find.text('Learn kit'), findsOneWidget);
    expect(find.text('MIDI latency'), findsOneWidget);
  });

  testWidgets('several devices: shows the one the practice screen would open',
      (t) async {
    await SettingsService.setMidiLastDeviceId('24:0');
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MeasurementSection(
          ports: FakePorts([
            (id: '20:0', name: 'Millenium', hasInput: true),
            (id: '24:0', name: 'Roland TD', hasInput: true),
          ]),
        ),
      ),
    ));
    await t.pumpAndSettle();
    expect(find.text('MIDI: Roland TD'), findsOneWidget);
    expect(find.textContaining('Millenium'), findsNothing);
  });

  testWidgets('desktop: no microphone promise, Mic marked untested',
      (t) async {
    debugDesktopOverride = true;
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: MeasurementSection(ports: FakePorts(const []))),
    ));
    await t.pumpAndSettle();
    expect(find.text('Mic (untested)'), findsOneWidget);
    expect(
        find.text('Auto: MIDI when a module is connected; the microphone only '
            'on the phone.'),
        findsOneWidget);
  });

  testWidgets('the setup subscription ends with the widget', (t) async {
    final ports = FakePorts(const []);
    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: MeasurementSection(ports: ports)),
    ));
    await t.pumpAndSettle();
    expect(ports.setup.hasListener, isTrue);
    await t.pumpWidget(const SizedBox());
    expect(ports.setup.hasListener, isFalse);
  });

  testWidgets('back from the latency screen refreshes the subtitle',
      (t) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: MeasurementSection(
            ports:
                FakePorts([(id: '20:0', name: 'Millenium', hasInput: true)]),
          ),
        ),
      ),
      GoRoute(
        path: '/settings/midi-calibration',
        builder: (context, __) => Scaffold(
          body: TextButton(
            onPressed: () async {
              await SettingsService.setMidiLatencyOffsetMsFor('Millenium', 18);
              if (context.mounted) context.pop();
            },
            child: const Text('save'),
          ),
        ),
      ),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.textContaining('Not calibrated yet'), findsOneWidget);
    await t.tap(find.text('MIDI latency'));
    await t.pumpAndSettle();
    await t.tap(find.text('save'));
    await t.pumpAndSettle();
    expect(find.text('Saved: 18 ms'), findsOneWidget);
  });
}
