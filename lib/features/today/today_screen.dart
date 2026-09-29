import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/design_tokens.dart';
import '../../shared/widgets/error_state.dart';
import '../practice/backdrop.dart';
import '../stats/stats_provider.dart';
import 'next_step.dart';
import 'next_step_provider.dart';

/// Light shadow behind white text on the photo.
const _photoShadow = [
  Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1)),
];

/// Start screen (K2): two doors — continue the path, or practice freely —
/// then streak and minutes, compact. Replaces the dashboard card stack.
/// Since 29.09. (Uli) a random photo fills the whole screen; the greeting
/// sits on it, the doors on paper below.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  /// Chosen once per screen instance — a rebuild must not swap the photo.
  late final String _backdrop = nextBackdrop();

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(nextStepProvider);
    final streak = ref.watch(streakDaysProvider);
    final today = ref.watch(todayStatusProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning.'
        : hour < 18
            ? 'Good afternoon.'
            : 'Good evening.';

    // The photo runs up behind the status bar, so the system icons are
    // light; there is no AppBar to set them.
    final screenHeight = MediaQuery.sizeOf(context).height;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _backdrop,
              fit: BoxFit.cover,
              // A missing file must never break the start screen.
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            // A light veil at the top for the white greeting; from the
            // middle down the photo fades into paper, where the doors sit.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x66101010),
                    Color(0x00101010),
                    Color(0x00FAF8F3),
                    AppColors.base,
                    AppColors.base,
                  ],
                  stops: [0.0, 0.30, 0.40, 0.60, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.lg,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  Row(
                    children: [
                      const _Eyebrow('Today', color: Colors.white70),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        color: Colors.white,
                        tooltip: 'Settings',
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  Text(greeting,
                      style: AppTypography.display.copyWith(
                          color: Colors.white, shadows: _photoShadow)),
                  // Leaves the photo room; the doors start on paper.
                  SizedBox(height: screenHeight * 0.30),
                  step.when(
                    data: (s) => _PathDoor(step: s),
                    loading: () => const SizedBox(height: 140),
                    error: (e, _) => ErrorStateWidget(
                      message: 'Could not load your next step.',
                      onRetry: () => ref.invalidate(nextStepProvider),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  const _FreeDoor(),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  _StatsRow(
                    streak: streak.valueOrNull ?? 0,
                    today: today.valueOrNull,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text, {this.color = AppColors.textMuted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppTypography.label.copyWith(color: color, letterSpacing: 1.0),
      );
}

class _PathDoor extends StatelessWidget {
  const _PathDoor({required this.step});
  final PathStep step;

  String? get _buttonLabel => switch (step.kind) {
        PathStepKind.exercise =>
          step.minutes > 0 ? 'Start · ${step.minutes} min' : 'Start',
        PathStepKind.setup => 'Set up your path',
        PathStepKind.dayDone || PathStepKind.programComplete => 'Open program',
        PathStepKind.restDay => null,
      };

  @override
  Widget build(BuildContext context) {
    final label = _buttonLabel;
    final route = step.route;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Continue the path', color: AppColors.paperAccent),
        const SizedBox(height: AppSpacing.xs),
        Text(step.title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          step.detail,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        if (label != null && route != null) ...[
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.push(route),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
            ),
            child: Text(label),
          ),
        ],
      ],
    );
  }
}

class _FreeDoor extends StatelessWidget {
  const _FreeDoor();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Practice freely'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Rudiments, etudes and technique studies.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () => context.go('/library'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Open library'),
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.streak, required this.today});
  final int streak;
  final TodayStatus? today;

  @override
  Widget build(BuildContext context) {
    final number = GoogleFonts.ibmPlexMono(
      fontSize: 30,
      fontWeight: FontWeight.w600,
      height: 1.05,
      color: AppColors.textPrimary,
    );
    final faint = number.copyWith(color: AppColors.textMuted);
    final label =
        AppTypography.body.copyWith(fontSize: 13, color: AppColors.textMuted);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak', style: number),
              Text('day streak', style: label),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('${today?.minutes ?? 0}', style: number),
                  Text('/${today?.goalMinutes ?? 0}', style: faint),
                ],
              ),
              Text('min today', style: label),
            ],
          ),
        ),
      ],
    );
  }
}
