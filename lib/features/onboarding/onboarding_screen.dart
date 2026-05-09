import 'package:flutter/material.dart';

import '../../data/local/settings_service.dart';
import '../../services/notification_service.dart';

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
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('🥁', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text(
                'Welcome to DrumCoach',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Train drum rudiments with a smart spaced-repetition system that adapts to your progress.',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
              ),
              const Spacer(),
              _SectionTitle('Daily practice goal'),
              const SizedBox(height: 12),
              _TargetPicker(
                value: _targetMinutes,
                onChanged: (v) => setState(() => _targetMinutes = v),
              ),
              const SizedBox(height: 28),
              _SectionTitle('Daily reminders'),
              const SizedBox(height: 12),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Let's go!",
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
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
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white70),
    );
  }
}

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
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(min),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.deepOrange.withValues(alpha: 0.18)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? Colors.deepOrange
                        : Colors.white.withValues(alpha: 0.1),
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$min',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: selected ? Colors.deepOrange : Colors.white,
                      ),
                    ),
                    const Text('min',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white54),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Remind me to practice',
                style: TextStyle(fontSize: 14)),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: Colors.deepOrange,
            activeTrackColor: Colors.deepOrange.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
