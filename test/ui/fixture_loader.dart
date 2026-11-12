import 'dart:io';

import 'package:drum_coach/content/analysis.dart';
import 'package:drum_coach/measure/session_record.dart';
import 'package:drum_coach/ui/feedback_screen.dart';

/// A reference session from test/fixtures/sessions as feedback arguments.
FeedbackArgs loadFixture(String name) {
  final path = 'test/fixtures/sessions/$name.jsonl';
  final record = decodeSessionJsonl(File(path).readAsStringSync());
  return FeedbackArgs(
      record: record, analysis: analyzeSession(record), path: path);
}
