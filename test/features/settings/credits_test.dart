import 'dart:io';

import 'package:drum_coach/features/settings/audio_credits.dart';
import 'package:drum_coach/features/settings/credits_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every shipped sound file: the kit and pad samples and the voice clips.
List<String> _shippedAudio() => [
      for (final dir in ['assets/audio', 'assets/voice'])
        for (final f in Directory(dir).listSync().whereType<File>())
          if (f.path.endsWith('.wav')) f.path.replaceAll(r'\', '/'),
    ]..sort();

void main() {
  test('every shipped audio file has exactly one credit with a licence', () {
    for (final path in _shippedAudio()) {
      final hits = audioCredits.where((c) => c.covers(path)).toList();
      expect(hits, hasLength(1), reason: path);
      expect(hits.single.licence, isNotEmpty, reason: path);
      expect(hits.single.licenceUrl, startsWith('https://'), reason: path);
    }
  });

  test('no credit names a file that does not ship', () {
    final shipped = _shippedAudio();
    for (final c in audioCredits) {
      for (final f in c.files) {
        expect(shipped.any((p) => f.endsWith('/') ? p.startsWith(f) : p == f),
            isTrue,
            reason: f);
      }
    }
  });

  test('no NC / ND / SA licence; CC BY entries name author and source', () {
    for (final c in audioCredits) {
      expect(c.licence, isNot(matches(RegExp(r'NC|ND|SA'))), reason: c.title);
      if (c.licence.startsWith('CC BY')) {
        expect(c.author, isNotEmpty, reason: c.title);
        expect(c.source, startsWith('https://'), reason: c.title);
      }
    }
  });

  test('assets/audio/CREDITS.md says the same as audioCredits', () {
    final md = File('assets/audio/CREDITS.md').readAsStringSync();
    for (final c in audioCredits) {
      for (final s in [c.title, c.author, c.source, c.licence, c.licenceUrl]) {
        expect(md, contains(s), reason: '${c.title}: $s');
      }
      for (final f in c.files) {
        expect(md, contains('`$f`'), reason: f);
      }
    }
  });

  testWidgets('the Credits page lists every source with its licence',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CreditsScreen()));
    await tester.pump();
    for (final c in audioCredits) {
      final title = find.text(c.title);
      await tester.scrollUntilVisible(title, 200,
          scrollable: find.byType(Scrollable).first);
      expect(title, findsOneWidget);
      expect(find.text('By ${c.author}'), findsOneWidget);
      expect(find.text('Licence: ${c.licence}'), findsOneWidget);
      expect(
          find.byWidgetPredicate(
              (w) => w is SelectableText && w.data == c.source),
          findsOneWidget);
    }
  });
}
