import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/app_card.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _targetMinutes = 20;
  bool _remindersEnabled = true;

  Future<void> _finish() async {
    await SettingsService.setPracticeTargetMinutes(_targetMinutes);
    await SettingsService.setReminderEnabled(_remindersEnabled);
    if (_remindersEnabled) {
      await NotificationService.scheduleDailyReminder();
    }
    await SettingsService.setOnboardingDone();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('🥁', style: TextStyle(fontSize: 64)),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Welcome to DrumCoach',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Train drum rudiments with a smart spaced-repetition system that adapts to your progress.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15, height: 1.5),
              ),
              const Spacer(),
              const _SectionTitle('Daily practice goal'),
              const SizedBox(height: AppSpacing.md),
              _TargetPicker(
                value: _targetMinutes,
                onChanged: (v) => setState(() => _targetMinutes = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionTitle('Daily reminders'),
              const SizedBox(height: AppSpacing.md),
              _ReminderToggle(
                enabled: _remindersEnabled,
                onChanged: (v) => setState(() => _remindersEnabled = v),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finish,
                  child: const Text("Let's go!"),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: AppColors.textSecondary),
    );
  }
}

// Deviates from the generic [AppSelectableChip] on purpose: the practice
// goal needs a distance-legible number, not a single-line label, so it
// keeps its own two-line layout while still drawing from the token set.
class _TargetPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TargetPicker({required this.value, required this.onChanged});

  static const _options = [15, 20, 30, 45];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((min) {
        final selected = value == min;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onChanged(min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.18)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(
                    color: selected ? AppColors.accent : AppColors.textFaint,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$min',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Text('min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _ReminderToggle({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Text(
              'Remind me to practice',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
