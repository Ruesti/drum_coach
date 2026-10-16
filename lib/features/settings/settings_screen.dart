import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/design_tokens.dart';
import '../../app/platform_support.dart';
import '../../data/local/session_log_service.dart';
import '../../data/local/settings_service.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_card.dart';
import '../coaching/midi/midi_port_service.dart';
import 'measurement_section.dart';
import 'sequence_repeats_row.dart';

const _donationUrl = 'https://ko-fi.com/drumcoach';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _targetMin;
  late int _repeats;
  late bool _haptics;
  late bool _reminders;
  final _apiKeyController = TextEditingController();
  bool _apiKeyObscured = true;

  /// One port service for the screen's lifetime (not one per build).
  final _midiPorts = MidiPortService();

  @override
  void initState() {
    super.initState();
    _targetMin = SettingsService.practiceTargetMinutes;
    _repeats = SettingsService.sequenceRepeats;
    _haptics = SettingsService.hapticsEnabled;
    _reminders = SettingsService.reminderEnabled;
    _apiKeyController.text = SettingsService.claudeApiKey;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _setTarget(int min) async {
    await SettingsService.setPracticeTargetMinutes(min);
    setState(() => _targetMin = min);
  }

  Future<void> _setRepeats(int n) async {
    await SettingsService.setSequenceRepeats(n);
    setState(() => _repeats = n);
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

  Future<void> _saveApiKey() async {
    await SettingsService.setClaudeApiKey(_apiKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved')),
      );
    }
  }

  Future<void> _openDonation() async {
    final uri = Uri.parse(_donationUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<void> _resetOnboarding() async {
    await SettingsService.resetOnboarding();
    if (mounted) {
      context.push('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Support ──────────────────────────────────────────────────
          _SectionLabel('SUPPORT'),
          const SizedBox(height: 10),
          _DonationCard(onTap: _openDonation),
          const SizedBox(height: 28),

          // ── Übungsziel ────────────────────────────────────────────────
          _SectionLabel('DAILY PRACTICE GOAL'),
          const SizedBox(height: 10),
          _TargetRow(value: _targetMin, onChanged: _setTarget),
          const SizedBox(height: 28),

          // ── Zeilenfolgen ──────────────────────────────────────────────
          _SectionLabel('LINE SEQUENCES'),
          const SizedBox(height: 10),
          SequenceRepeatsRow(value: _repeats, onChanged: _setRepeats),
          const SizedBox(height: 6),
          Text('Each selected line plays this many times before the next one.',
              style: AppTypography.label.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 28),

          // ── Gerät ─────────────────────────────────────────────────────
          _SectionLabel('DEVICE'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.vibration,
            title: 'Haptic feedback',
            subtitle: 'Vibration on accent strokes',
            value: _haptics,
            onChanged: _setHaptics,
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Daily reminder',
            subtitle: 'Reminds you to practice every day',
            value: _reminders,
            onChanged: _setReminders,
          ),
          const SizedBox(height: 28),

          // ── Measurement ────────────────────────────────────────────────
          _SectionLabel('MEASUREMENT'),
          const SizedBox(height: 10),
          MeasurementSection(ports: _midiPorts),
          const SizedBox(height: 28),

          // ── Data & coaching (export, latency, AI coach) ────────────────
          _SectionLabel('DATA & COACHING'),
          const SizedBox(height: 10),
          AppCard(
            onTap: () async {
              final ExportOutcome out;
              try {
                out = await SessionLogService.exportDayTo(
                  DateTime.now(),
                  shareAvailable: fileShareAvailable,
                  share: (f) => SharePlus.instance
                      .share(ShareParams(files: [XFile(f.path)])),
                );
              } catch (e) {
                debugPrint('export failed: $e');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export failed.')));
                return;
              }
              final message = SessionLogService.exportMessage(out);
              if (!context.mounted || message == null) return;
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(message)));
            },
            child: Row(
              children: [
                const Icon(Icons.ios_share,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Export today's session logs",
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        fileShareAvailable
                            ? 'Raw data as JSONL via the share dialog'
                            : 'Raw data as JSONL, saved to '
                                'Documents/drum_coach',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textFaint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => context.push('/settings/latency-calibration'),
            child: Row(
              children: [
                const Icon(Icons.graphic_eq,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Latency calibration',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(
                        SettingsService.latencyOffsetMs != null
                            ? 'Saved: ${SettingsService.latencyOffsetMs!.round()} ms'
                            : 'Not calibrated yet',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textFaint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (aiCoachingAvailable) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Claude API Key',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Get a key at console.anthropic.com',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _apiKeyObscured,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: 'sk-ant-…',
                    hintStyle: const TextStyle(color: AppColors.textFaint),
                    filled: true,
                    fillColor: AppColors.inset,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _apiKeyObscured ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _apiKeyObscured = !_apiKeyObscured),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saveApiKey,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Save API Key'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: () => context.push('/coaching/exercise-generator'),
            child: ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppColors.textMuted),
              title: const Text('Exercise Generator',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('AI-generated custom patterns',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
          ),
          ],
          const SizedBox(height: 8),
          AppCard(
            padding: EdgeInsets.zero,
            onTap: _resetOnboarding,
            child: ListTile(
              leading: const Icon(Icons.replay, color: AppColors.textMuted),
              title: const Text('Show onboarding again',
                  style: TextStyle(fontSize: 14)),
              subtitle: const Text('Restarts the intro from the beginning',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
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
            color: AppColors.accent,
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
      color: AppColors.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
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
                    const Text(
                      'Enjoying the app? Buy me a beer!',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: AppColors.textMuted, size: 18),
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
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _options.map((min) {
        return AppSelectableChip(
          label: '$min min',
          selected: value == min,
          onTap: () => onChanged(min),
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.textMuted),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accent,
        activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
      ),
    );
  }
}
