import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/error_state.dart';
import '../../shared/widgets/notation_staff_widget.dart';
import '../lessons/models/rudiment.dart';
import 'services/ai_coaching_service.dart';

/// Builds the [Rudiment] shown for a freshly AI-generated sticking
/// [pattern]. Extracted from the widget so it's unit-testable without
/// pumping the screen or mocking the network call.
Rudiment buildGeneratedRudiment(List<StrokeBeat> pattern) {
  return Rudiment(
    id: 'generated',
    name: 'Generated',
    description: '',
    minBpm: 80,
    targetBpm: 120,
    difficulty: Difficulty.beginner,
    sticking: pattern,
    gridUnit: NoteGrid.eighth,
    beatsPerBar: 4,
    source: ExerciseSource.generated,
  );
}

class ExerciseGeneratorScreen extends StatefulWidget {
  const ExerciseGeneratorScreen({super.key});

  @override
  State<ExerciseGeneratorScreen> createState() =>
      _ExerciseGeneratorScreenState();
}

class _ExerciseGeneratorScreenState extends State<ExerciseGeneratorScreen> {
  final _controller = TextEditingController();
  final _aiService = AICoachingService();

  List<StrokeBeat>? _pattern;
  bool _isLoading = false;
  String? _error;

  Future<void> _generate() async {
    final description = _controller.text.trim();
    if (description.isEmpty) return;

    final apiKey = SettingsService.claudeApiKey;
    if (apiKey.isEmpty) {
      setState(() => _error = 'Enter your Claude API key in Settings first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _pattern = null;
    });

    final result = await _aiService.generateExercise(
      apiKey: apiKey,
      description: description,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result == null || result.isEmpty) {
        _error = 'Could not generate a pattern. Try a different description.';
      } else {
        _pattern = result;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise Generator')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Describe the pattern you want to practice:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'e.g. "8-beat pattern combining flams and paradiddles with accents on beats 1 and 5"',
                  hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _generate(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generate,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? 'Generating…' : 'Generate Pattern'),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorStateWidget(
                  message: _error!,
                  compact: true,
                  onRetry: _generate,
                ),
              ],

              if (_pattern != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Generated Pattern',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  child: NotationStaffWidget(
                    rudiment: buildGeneratedRudiment(_pattern!),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_pattern!.length} beats  ·  '
                  '${_pattern!.where((b) => b.hand == Hand.right).length}R / '
                  '${_pattern!.where((b) => b.hand == Hand.left).length}L',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tip: Regenerate for variations, or adjust the description.',
                  style: TextStyle(
                    color: AppColors.textFaint,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
