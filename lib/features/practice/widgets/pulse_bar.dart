import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/design_tokens.dart';

/// Visible size of a stroke: the pattern's volume levels (see
/// `defaultBeatVolume`: accent 2.0, normal 0.85, ghost/grace 0.25, rest 0)
/// mapped to three pulse sizes and silence.
double pulseLevel(double volume) {
  if (volume <= 0) return 0.0;
  if (volume >= 1.2) return 1.0;
  if (volume <= 0.3) return 0.3;
  return 0.6;
}

/// Position in the loop (0..1) at [now], run forward from the last onset the
/// engine reported ([anchorTick] at [anchorAt]) with the tick duration — so
/// the marker moves between notes instead of jumping at each one. A global
/// (never wrapping) anchor tick is folded into the loop.
double progressAt({
  required int anchorTick,
  required DateTime anchorAt,
  required DateTime now,
  required double tickDurMs,
  required int totalTicks,
}) {
  final elapsedTicks =
      now.difference(anchorAt).inMicroseconds / 1000.0 / tickDurMs;
  var pos = (anchorTick + elapsedTicks) % totalTicks;
  if (pos < 0) pos += totalTicks;
  return pos / totalTicks;
}

/// The running pulse bar under the sheet (decided 27.09., replaces the digit
/// counter): a marker runs through the loop, quarter marks on the track, and
/// each onset flashes a pulse at the marker whose size shows the volume —
/// accent big and bright, normal medium, ghost small and faint.
class PulseBar extends StatefulWidget {
  const PulseBar({
    super.key,
    required this.playing,
    required this.anchorTick,
    required this.anchorAt,
    required this.tickDurMs,
    required this.totalTicks,
    required this.ticksPerQuarter,
    required this.pulseVolume,
  });

  final bool playing;

  /// Global tick of the latest onset (-1 = none yet) and when it sounded.
  final int anchorTick;
  final DateTime? anchorAt;
  final double tickDurMs;
  final int totalTicks;
  final int ticksPerQuarter;

  /// Volume of the latest onset (pattern scale), 0 = rest.
  final double pulseVolume;

  @override
  State<PulseBar> createState() => _PulseBarState();
}

class _PulseBarState extends State<PulseBar> with TickerProviderStateMixin {
  late final Ticker _ticker;
  late final AnimationController _flash;
  final _progress = ValueNotifier<double>(0);
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300))
      ..value = 1;
    _ticker = createTicker((_) => _updateProgress());
    _syncTicker();
    // Built while an onset is already sounding (screen opened mid-loop, or
    // a rebuild that replaced the widget): flash that onset too.
    if (widget.playing && widget.anchorTick >= 0) {
      _level = pulseLevel(widget.pulseVolume);
      _flash.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(PulseBar old) {
    super.didUpdateWidget(old);
    if (widget.playing && widget.anchorTick != old.anchorTick &&
        widget.anchorTick >= 0) {
      _level = pulseLevel(widget.pulseVolume);
      _flash.forward(from: 0);
    }
    if (widget.playing != old.playing) _syncTicker();
    _updateProgress();
  }

  void _syncTicker() {
    if (widget.playing) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
      _level = 0;
      _progress.value = 0;
    }
  }

  void _updateProgress() {
    final at = widget.anchorAt;
    if (!widget.playing || at == null || widget.anchorTick < 0 ||
        widget.totalTicks <= 0) {
      _progress.value = 0;
      return;
    }
    _progress.value = progressAt(
      anchorTick: widget.anchorTick,
      anchorAt: at,
      now: DateTime.now(),
      tickDurMs: widget.tickDurMs,
      totalTicks: widget.totalTicks,
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _flash.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quarters = widget.ticksPerQuarter > 0
        ? widget.totalTicks ~/ widget.ticksPerQuarter
        : 0;
    return SizedBox(
      height: 28,
      child: AnimatedBuilder(
        animation: Listenable.merge([_progress, _flash]),
        builder: (_, __) => CustomPaint(
          painter: PulseBarPainter(
            progress: _progress.value,
            quarterMarks: quarters,
            pulse: _level * (1 - _flash.value),
            playing: widget.playing,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class PulseBarPainter extends CustomPainter {
  PulseBarPainter({
    required this.progress,
    required this.quarterMarks,
    required this.pulse,
    required this.playing,
  });

  final double progress;
  final int quarterMarks;

  /// Current flash strength 0..1 (level × remaining fade).
  final double pulse;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    final track = Paint()
      ..color = PracticeColors.textFaint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), track);

    final mark = Paint()
      ..color = PracticeColors.textMuted
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var q = 0; q < quarterMarks; q++) {
      final x = size.width * q / quarterMarks;
      canvas.drawLine(Offset(x, midY - 5), Offset(x, midY + 5), mark);
    }

    final x = size.width * progress;
    if (pulse > 0) {
      canvas.drawCircle(
        Offset(x, midY),
        4 + 10 * pulse,
        Paint()..color = PracticeColors.accent.withValues(alpha: pulse),
      );
    }
    final marker = Paint()
      ..color = playing
          ? PracticeColors.accent
          : PracticeColors.textFaint
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, 3), Offset(x, size.height - 3), marker);
  }

  @override
  bool shouldRepaint(PulseBarPainter old) =>
      old.progress != progress ||
      old.pulse != pulse ||
      old.quarterMarks != quarterMarks ||
      old.playing != playing;
}
