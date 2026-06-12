import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../lessons/models/rudiment.dart';
import '../models/session_analysis.dart';

class AICoachingService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _coachSystem =
      'You are an expert drum coach. Give 2-3 sentences of specific, actionable '
      'feedback in English based on the practice session data. Be concise and '
      'encouraging. Focus on the single most impactful thing to improve.';
  static const _generatorSystem =
      'You are an expert drum teacher. Generate a sticking pattern as a JSON array. '
      'Each element must be: {"hand":"right"|"left","isAccent":bool,"isGhost":bool}. '
      'Return ONLY the raw JSON array — no markdown, no explanation, no extra text. '
      'Use 8–32 beats. Accent the first beat of each rhythmic group.';

  Future<String?> getCoachingFeedback({
    required String apiKey,
    required String rudimentName,
    required int achievedBpm,
    required int targetBpm,
    required int durationSeconds,
    required int rating,
    SessionAnalysis? analysis,
  }) async {
    final ratingLabel = switch (rating) {
      1 => 'Struggled',
      2 => 'OK',
      _ => 'Solid',
    };

    final timingLine = analysis?.timing != null
        ? 'Timing: overall ${analysis!.timing!.overallDeviationMs.toStringAsFixed(1)} ms '
            '(${analysis.timing!.overallDeviationMs > 0 ? "late" : "early"}), '
            'right hand ${analysis.timing!.rightHandDeviationMs.toStringAsFixed(1)} ms, '
            'left hand ${analysis.timing!.leftHandDeviationMs.toStringAsFixed(1)} ms, '
            'jitter ${analysis.timing!.jitterMs.toStringAsFixed(1)} ms'
        : null;

    final dynamicsLine = analysis?.dynamics != null
        ? 'Dynamics: right ${(analysis!.dynamics!.rightHandLevel * 100).round()}%, '
            'left ${(analysis.dynamics!.leftHandLevel * 100).round()}%'
        : null;

    final lines = [
      'Rudiment: $rudimentName',
      'BPM: $achievedBpm / $targetBpm target (${(achievedBpm / targetBpm * 100).round()}%)',
      'Duration: ${durationSeconds ~/ 60}min ${durationSeconds % 60}s',
      'Self-rating: $ratingLabel',
      if (timingLine != null) timingLine,
      if (dynamicsLine != null) dynamicsLine,
      if (analysis != null)
        'Detected hits: ${analysis.detectedHits} / expected: ${analysis.expectedHits}',
    ];

    return _call(
      apiKey: apiKey,
      system: _coachSystem,
      userMessage: lines.join('\n'),
      maxTokens: 200,
    );
  }

  Future<List<StrokeBeat>?> generateExercise({
    required String apiKey,
    required String description,
  }) async {
    final text = await _call(
      apiKey: apiKey,
      system: _generatorSystem,
      userMessage: description,
      maxTokens: 512,
    );
    if (text == null) return null;

    try {
      // Strip optional markdown fences that the model might add anyway
      final jsonStr = text
          .trim()
          .replaceAll(RegExp(r'^```(?:json)?\s*'), '')
          .replaceAll(RegExp(r'\s*```$'), '');
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return StrokeBeat(
          hand: m['hand'] == 'right' ? Hand.right : Hand.left,
          isAccent: (m['isAccent'] as bool?) ?? false,
          isGhost: (m['isGhost'] as bool?) ?? false,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _call({
    required String apiKey,
    required String system,
    required String userMessage,
    required int maxTokens,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: jsonEncode({
              'model': _model,
              'max_tokens': maxTokens,
              'system': system,
              'messages': [
                {'role': 'user', 'content': userMessage},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = (data['content'] as List).first as Map<String, dynamic>;
      return content['text'] as String?;
    } catch (_) {
      return null;
    }
  }
}
