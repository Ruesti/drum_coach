import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/local/settings_service.dart';
import '../../services/notification_service.dart';

// Replace with your own Ko-fi / Buy Me a Coffee URL
const _donationUrl = 'https://ko-fi.com/drumcoach';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _targetMin;
  late bool _haptics;
  late bool _reminders;

  @override
  void initState() {
    super.initState();
    _targetMin = SettingsService.practiceTargetMinutes;
    _haptics = SettingsService.hapticsEnabled;
    _reminders = SettingsService.reminderEnabled;
  }

  Future<void> _setTarget(int min) async {
    await SettingsService.setPracticeTargetMinutes(min);
    setState(() => _targetMin = min);
  }

  Future<void> _setHaptics(bool v) async {
    await SettingsService.setHapticsEnabled(v);
    setState(() => _haptics = v);
  }

  Future<void> _setReminders(bool v) async {
    await SettingsService.setReminderEnabled(v);
    if (v) {
      await NotificationService.scheduleDailyReminder();
    } else {
      await NotificationService.cancelReminder();
    }
    setState(() => _reminders = v);
  }

  Future<void> _openDonation() async {
    final uri = Uri.parse(_donationUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link konnte nicht geöffnet werden')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Support ──────────────────────────────────────────────────
          _SectionLabel('SUPPORT'),
          const SizedBox(height: 10),
          _DonationCard(onTap: _openDonation),
          const SizedBox(height: 28),

          // ── Übungsziel ────────────────────────────────────────────────
          _SectionLabel('ÜBUNGSZIEL PRO TAG'),
          const SizedBox(height: 10),
          _TargetRow(
            value: _targetMin,
            onChanged: _setTarget,
          ),
          const SizedBox(height: 28),

          // ── Gerät ─────────────────────────────────────────────────────
          _SectionLabel('GERÄT'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.vibration,
            title: 'Haptisches Feedback',
            subtitle: 'Vibration auf Akzentschlägen',
            value: _haptics,
            onChanged: _setHaptics,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Tägliche Erinnerung',
            subtitle: 'Erinnert dich täglich ans Üben',
            value: _reminders,
            onChanged: _setReminders,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.deepOrange,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DonationCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.deepOrange.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.deepOrange.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              const Text('🍺', style: TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buy me a Beer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Gefällt dir die App? Spendiere ein Bier!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.white38, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _TargetRow({required this.value, required this.onChanged});

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
                    const Text(
                      'min',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: Colors.white54),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.deepOrange,
        activeTrackColor: Colors.deepOrange.withValues(alpha: 0.4),
      ),
    );
  }
}
