import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/app_card.dart';
import '../coaching/services/latency_calibration_service.dart';
import '../coaching/services/latency_estimator.dart';

/// Loopback latency calibration (§1.3): plays clicks over the speaker,
/// records them through the practice-session audio path and stores the
/// measured output+input latency. Repeat runs show the spread so the
/// acceptance criterion (three runs, spread < 5 ms) is checkable on screen.
class LatencyCalibrationScreen extends StatefulWidget {
  const LatencyCalibrationScreen({super.key});

  @override
  State<LatencyCalibrationScreen> createState() =>
      _LatencyCalibrationScreenState();
}

class _LatencyCalibrationScreenState extends State<LatencyCalibrationScreen> {
  final List<LatencyEstimate> _runs = [];
  bool _running = false;
  bool _failed = false;

  double get _median {
    final sorted = _runs.map((r) => r.offsetMs).toList()..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  double get _spread {
    final offsets = _runs.map((r) => r.offsetMs).toList();
    offsets.sort();
    return offsets.last - offsets.first;
  }

  Future<void> _measure() async {
    setState(() {
      _running = true;
      _failed = false;
    });
    final granted = await Permission.microphone.request();
    LatencyEstimate? result;
    if (granted.isGranted) {
      result = await LatencyCalibrationService.runOnce();
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      if (result == null) {
        _failed = true;
      } else {
        _runs.add(result);
      }
    });
  }

  Future<void> _save() async {
    await SettingsService.setLatencyOffsetMs(_median);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Latenz gespeichert: ${_median.round()} ms')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stored = SettingsService.latencyOffsetMs;
    final storedAt = SettingsService.latencyCalibratedAt;

    return Scaffold(
      appBar: AppBar(title: const Text('Latenz-Kalibrierung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Text(
              'Misst den Zeitversatz zwischen geplantem Klick und Aufnahme '
              '(Ausgabe- plus Eingabelatenz). Kopfhörer abziehen, '
              'Lautstärke hoch, ruhige Umgebung — dann Messen '
              '(je Lauf 20 Klicks, ~10 Sekunden). Für einen belastbaren '
              'Wert dreimal messen; die Spannweite sollte unter 5 ms liegen.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          if (stored != null)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.solidStreak),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gespeichert: ${stored.round()} ms'
                      '${storedAt != null ? ' · ${storedAt.day}.${storedAt.month}.${storedAt.year}' : ''}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          for (var i = 0; i < _runs.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Messung ${i + 1}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 13)),
                        const Spacer(),
                        Text(
                          '${_runs[i].offsetMs.toStringAsFixed(1)} ms · '
                          '${_runs[i].matchedClicks}/${_runs[i].totalClicks} Klicks',
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (_runs[i].blockSpreadMs(3) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Blöcke: ${_runs[i].blockOffsets(3).map((b) => b.toStringAsFixed(1)).join(' / ')} '
                          '· Δ ${_runs[i].blockSpreadMs(3)!.toStringAsFixed(1)} ms in dieser Aufnahme',
                          style: TextStyle(
                              color: _runs[i].blockSpreadMs(3)! < 5
                                  ? AppColors.solidStreak
                                  : AppColors.struggled,
                              fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_runs.length >= 2) ...[
            const SizedBox(height: 6),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Median: ${_median.toStringAsFixed(1)} ms · '
                    'Spannweite: ${_spread.toStringAsFixed(1)} ms',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _spread < 5
                            ? 'Reproduzierbar (Spannweite < 5 ms) — Wert kann '
                                'gespeichert werden.'
                            : 'Spannweite ≥ 5 ms — Umgebung beruhigen und '
                                'erneut messen.',
                        style: TextStyle(
                            color: _spread < 5
                                ? AppColors.solidStreak
                                : AppColors.struggled,
                            fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_failed) ...[
            const SizedBox(height: 6),
            const AppCard(
              child: Text(
                'Messung fehlgeschlagen — zu wenige Klicks in der Aufnahme '
                'gefunden. Lautstärke prüfen, Mikrofon freihalten, erneut '
                'versuchen.',
                style: TextStyle(color: AppColors.struggled, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _running ? null : _measure,
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.graphic_eq),
            label: Text(_running ? 'Misst…' : 'Messen'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _runs.isEmpty || _running ? null : _save,
            child: Text(_runs.isEmpty
                ? 'Wert speichern'
                : 'Wert speichern (${_median.round()} ms)'),
          ),
        ],
      ),
    );
  }
}
