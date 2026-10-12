import 'dart:io';

import 'package:drum_coach/data/local/session_log_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('export_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<File?> write(Directory dir) =>
      SessionLogService.writeExportFile('sessions_2026-10-12.jsonl', '{}\n',
          dir: dir);

  test('desktop: saved into <documents>/drum_coach, never shared', () async {
    final shared = <File>[];
    final out = await SessionLogService.deliverExport(
      write: write,
      shareAvailable: false,
      share: (f) async => shared.add(f),
      documentsDir: () async => tmp,
    );
    expect(shared, isEmpty);
    expect(out.shared, isFalse);
    expect(out.file!.path, '${tmp.path}/drum_coach/sessions_2026-10-12.jsonl');
    expect(out.file!.readAsStringSync(), '{}\n');
    expect(SessionLogService.exportMessage(out),
        'Saved to ${tmp.path}/drum_coach/sessions_2026-10-12.jsonl');
  });

  test('phone: temp file handed to the share sheet', () async {
    final shared = <File>[];
    final out = await SessionLogService.deliverExport(
      write: write,
      shareAvailable: true,
      share: (f) async => shared.add(f),
      tempDir: () async => tmp,
    );
    expect(shared.single.path, '${tmp.path}/sessions_2026-10-12.jsonl');
    expect(out.shared, isTrue);
    expect(SessionLogService.exportMessage(out), isNull);
  });

  test('nothing to export: no share, the empty message', () async {
    final out = await SessionLogService.deliverExport(
      write: (_) async => null,
      shareAvailable: false,
      share: (_) async => fail('must not share'),
      documentsDir: () async => tmp,
    );
    expect(out.file, isNull);
    expect(SessionLogService.exportMessage(out), 'No session logs today yet.');
  });
}
