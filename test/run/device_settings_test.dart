import 'dart:io';

import 'package:drum_coach/measure/kit.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/run/device_settings.dart';
import 'package:drum_coach/run/session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('settings: mapping and latency persist per device name', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final s = DeviceSettings(p);
    expect(s.mappingFor('A').instrumentFor(38), KitInstrument.snare);
    expect(s.latencyFor('A'), isNull);

    await s.saveMapping('A', KitMapping.gm().assign(KitInstrument.kick, 35));
    await s.saveLatency('A', 21, 3);
    await s.saveLatency('A', 23, 4);

    final again = DeviceSettings(p);
    expect(again.mappingFor('A').instrumentFor(35), KitInstrument.kick);
    expect(again.mappingFor('B').instrumentFor(35), isNull);
    expect(again.latencyFor('A'), (offsetMs: 23.0, spreadMs: 4.0));
    expect(again.previousLatencyFor('A'), (offsetMs: 21.0, spreadMs: 3.0));
    expect(again.latencyFor('B'), isNull);
  });

  group('SessionStore', () {
    SessionRecord rec(String id, DateTime at) => SessionRecord(
        exerciseId: id,
        bpm: 80,
        firstBeatMs: 1,
        latencyOffsetMs: null,
        deviceName: 'd',
        mapping: KitMapping.gm(),
        platform: 'test',
        recordedAt: at,
        strokes: const []);

    test('saves, lists newest first, skips broken files', () async {
      final dir = await Directory.systemTemp.createTemp('store');
      addTearDown(() => dir.delete(recursive: true));
      final store = SessionStore(dir);
      final f1 = await store.save(rec('rock8', DateTime(2026, 1, 1, 10)));
      await store.save(rec('rock8', DateTime(2026, 1, 2, 10)));
      await store.save(rec('entry', DateTime(2026, 1, 3, 10)));
      await File('${dir.path}/sessions/rock8-bad.jsonl').writeAsString('nope');
      expect(f1.path, endsWith('sessions/rock8-20260101-100000.jsonl'));
      final r = await store.recent('rock8');
      expect(r.map((e) => e.recordedAt.day), [2, 1]);
      expect((await store.recent('rock8', limit: 1)).length, 1);
      expect(
          await SessionStore(Directory('${dir.path}/x')).recent('a'), isEmpty);
    });
  });
}
