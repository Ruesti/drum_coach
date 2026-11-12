import 'dart:io';

import 'package:drum_coach/app/app.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:drum_coach/run/session_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/midi_fakes.dart';
import '../run/fakes.dart';

/// Keeps saved records in memory; the path is made up.
class _MemoryStore implements SessionStore {
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

Future<_MemoryStore> _pumpApp(WidgetTester tester, FakeSource source) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = _MemoryStore();
  await tester.pumpWidget(ProviderScope(overrides: [
    midiPortsProvider.overrideWithValue(FakeMidiPorts(port: FakeMidiPort())),
    deviceSettingsProvider.overrideWithValue(DeviceSettings(prefs)),
    sessionStoreProvider.overrideWithValue(store),
    clickOutProvider.overrideWithValue(FakeOut(FakeClock())),
    openStrokeSourceProvider
        .overrideWithValue((deviceId, mapping) async => source),
    platformNameProvider.overrideWithValue('test'),
  ], child: const DrumCoachApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entry exercise'));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('run: finished run is saved and opens Feedback', (tester) async {
    // FakeOut's clock lies far in the past, so the run ends at once.
    final source = FakeSource();
    final store = await _pumpApp(tester, source);
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
    final store = await _pumpApp(tester, source);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(
        find.text('MIDI device disconnected — run discarded'), findsOneWidget);
    expect(store.saved, isEmpty);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Basic Rock Beat'), findsOneWidget);
  });
}
