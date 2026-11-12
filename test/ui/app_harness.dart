import 'dart:io';

import 'package:drum_coach/app/app.dart';
import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/midi/stroke_source.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:drum_coach/run/session_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/midi_fakes.dart';
import '../run/fakes.dart';

/// Keeps saved records in memory; the path is made up.
class MemoryStore implements SessionStore {
  final saved = <SessionRecord>[];
  @override
  Directory get root => Directory('/mem');
  @override
  Future<File> save(SessionRecord r) async {
    saved.add(r);
    return File('/mem/sessions/${r.exerciseId}-test.jsonl');
  }

  @override
  Future<List<SessionRecord>> recent(String exerciseId,
          {int limit = 10}) async =>
      [
        for (final r in saved.reversed)
          if (r.exerciseId == exerciseId) r
      ].take(limit).toList();
}

/// Pumps the app with fakes. [open] defaults to a new [FakeSource] per call
/// (collected in [sources]); [clock] drives the click and the controllers.
Future<MemoryStore> pumpApp(
  WidgetTester tester, {
  required FakeClock clock,
  FakeOut? out,
  List<FakeSource>? sources,
  Future<StrokeSource?> Function(String, KitMapping)? open,
  void Function(DeviceSettings)? settings,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final s = DeviceSettings(prefs);
  settings?.call(s);
  final store = MemoryStore();
  await tester.pumpWidget(ProviderScope(overrides: [
    midiPortsProvider.overrideWithValue(FakeMidiPorts(port: FakeMidiPort())),
    deviceSettingsProvider.overrideWithValue(s),
    sessionStoreProvider.overrideWithValue(store),
    clickOutProvider.overrideWithValue(out ?? FakeOut(clock)),
    runClockProvider
        .overrideWithValue((nowMs: () => clock.now, wait: clock.wait)),
    openStrokeSourceProvider.overrideWithValue(open ??
        (deviceId, mapping) async {
          final src = FakeSource();
          sources?.add(src);
          return src;
        }),
    platformNameProvider.overrideWithValue('test'),
  ], child: const DrumCoachApp()));
  await tester.pumpAndSettle();
  return store;
}
