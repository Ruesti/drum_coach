import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/error_state.dart';

class CoachFeedbackCard extends StatelessWidget {
  final String? feedback;
  final bool isLoading;
  final bool hasAnalysis;

  const CoachFeedbackCard({
    super.key,
    required this.feedback,
    required this.isLoading,
    required this.hasAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.coach,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🥁', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text(
                'Coach Feedback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              const AppBadge(label: 'AI', color: AppColors.accent),
            ],
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.accent,
                  ),
                ),
              ),
            )
          else if (feedback != null)
            Text(
              feedback!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            )
          else if (!hasAnalysis)
            const Text(
              'No microphone data captured. Enable the mic during your next session for personalised coaching.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            )
          else
            const ErrorStateWidget(
              message: 'Could not reach the coaching service. Check your API key in Settings.',
              compact: true,
            ),
        ],
      ),
    );
  }
}
