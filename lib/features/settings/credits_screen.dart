import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/app_card.dart';
import 'audio_credits.dart';

/// Settings → Credits: who recorded the sounds the app plays, where they
/// come from and under which licence ([audioCredits], the same list as
/// `assets/audio/CREDITS.md`). Source links are selectable text (no
/// browser hop needed to copy them).
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Sounds',
              style: AppTypography.subtitle.copyWith(color: AppColors.accent)),
          const SizedBox(height: 10),
          for (final c in audioCredits) ...[
            _CreditCard(credit: c),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credit});
  final AudioCredit credit;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppColors.textMuted, fontSize: 12);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(credit.title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('By ${credit.author}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text('Licence: ${credit.licence}',
              style: const TextStyle(fontSize: 13)),
          SelectableText(credit.licenceUrl, style: muted),
          const SizedBox(height: 4),
          const Text('Source', style: muted),
          SelectableText(credit.source, style: const TextStyle(fontSize: 13)),
          if (credit.note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(credit.note, style: muted),
          ],
          const SizedBox(height: 4),
          Text('Files: ${credit.files.join(', ')}', style: muted),
        ],
      ),
    );
  }
}
