import 'dart:io';

import 'package:drum_coach/app/app.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:drum_coach/run/session_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/midi_fakes.dart';

class _EmptyStore implements SessionStore {
  @override
  Directory get root => Directory('/nonexistent');
  @override
  Future<File> save(SessionRecord r) => throw UnimplementedError();
  @override
  Future<List<SessionRecord>> recent(String exerciseId,
          {int limit = 10}) async =>
      const [];
}

Future<void> _pumpApp(WidgetTester tester, FakeMidiPorts ports) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(overrides: [
    midiPortsProvider.overrideWithValue(ports),
    deviceSettingsProvider.overrideWithValue(DeviceSettings(prefs)),
    sessionStoreProvider.overrideWithValue(_EmptyStore()),
  ], child: const DrumCoachApp()));
  await tester.pumpAndSettle();
}

ListTile _tile(WidgetTester tester, String title) => tester.widget<ListTile>(
    find.ancestor(of: find.text(title), matching: find.byType(ListTile)));

void main() {
  testWidgets('home without device: exercise tiles disabled', (tester) async {
    await _pumpApp(tester, FakeMidiPorts());
    expect(find.text('No MIDI device'), findsOneWidget);
    expect(find.text('Setup'), findsOneWidget);
    expect(_tile(tester, 'Entry exercise').enabled, isFalse);
    expect(_tile(tester, 'Basic Rock Beat').enabled, isFalse);
  });

  testWidgets('home with device: name shown, tiles enabled', (tester) async {
    await _pumpApp(tester, FakeMidiPorts(port: FakeMidiPort()));
    expect(find.text('Fake Module'), findsOneWidget);
    expect(_tile(tester, 'Entry exercise').enabled, isTrue);
    expect(_tile(tester, 'Basic Rock Beat').enabled, isTrue);
    expect(find.text('Not played yet'), findsNWidgets(2));
  });
}
