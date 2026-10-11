import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/midi_port_service.dart';
import 'package:drum_coach/features/settings/measurement_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePorts implements MidiPortService {
  FakePorts(this.list);
  final List<({String id, String name, bool hasInput})> list;
  @override
  Future<List<({String id, String name, bool hasInput})>> inputDevices() async =>
      list;
  @override
  Future<MidiPort?> open(String deviceId) async => null;
  @override
  Stream<void> get setupChanges => const Stream.empty();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
  });

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
}
