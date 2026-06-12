import 'package:flutter/material.dart';

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
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.deepOrange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
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
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            )
          else if (feedback != null)
            Text(
              feedback!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.5,
              ),
            )
          else if (!hasAnalysis)
            const Text(
              'No microphone data captured. Enable the mic during your next session for personalised coaching.',
              style: TextStyle(fontSize: 12, color: Colors.white38, height: 1.4),
            )
          else
            const Text(
              'Could not reach the coaching service. Check your API key in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.white38, height: 1.4),
            ),
        ],
      ),
    );
  }
}
