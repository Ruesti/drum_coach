import 'dart:io';

import '../measure/session_record.dart';

/// Sessions as JSONL files: `<root>/sessions/<exerciseId>-<yyyyMMdd-HHmmss>.jsonl`.
class SessionStore {
  SessionStore(this.root);

  final Directory root;

  Directory get _dir => Directory('${root.path}/sessions');

  static String _two(int n) => n.toString().padLeft(2, '0');

  Future<File> save(SessionRecord r) async {
    await _dir.create(recursive: true);
    final t = r.recordedAt.toLocal();
    final stamp = '${t.year.toString().padLeft(4, '0')}${_two(t.month)}'
        '${_two(t.day)}-${_two(t.hour)}${_two(t.minute)}${_two(t.second)}';
    final file = File('${_dir.path}/${r.exerciseId}-$stamp.jsonl');
    await file.writeAsString(encodeSessionJsonl(r));
    return file;
  }

  /// Newest first; files that fail to decode are skipped.
  Future<List<SessionRecord>> recent(String exerciseId,
      {int limit = 10}) async {
    if (!await _dir.exists()) return const [];
    final prefix = '$exerciseId-';
    final files = <File>[];
    await for (final e in _dir.list()) {
      final name = e.uri.pathSegments.last;
      if (e is File && name.startsWith(prefix) && name.endsWith('.jsonl')) {
        files.add(e);
      }
    }
    final out = <SessionRecord>[];
    for (final f in files) {
      try {
        final r = decodeSessionJsonl(await f.readAsString());
        if (r.exerciseId == exerciseId) out.add(r);
      } on FormatException {
        continue;
      }
    }
    out.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return out.take(limit).toList();
  }
}
