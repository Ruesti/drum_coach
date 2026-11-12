import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../audio/click_player.dart';
import '../content/analysis.dart';
import '../content/exercises.dart';
import '../measure/kit.dart';
import '../measure/timestamp_mapper.dart';
import '../midi/midi_port_service.dart';
import '../midi/midi_stroke_source.dart';
import '../midi/stroke_source.dart';
import '../run/device_settings.dart';
import '../run/session_store.dart';
import '../skill/gate.dart';
import '../ui/calibration_screen.dart';
import '../ui/feedback_screen.dart';
import '../ui/home_screen.dart';
import '../ui/kit_learn_screen.dart';
import '../ui/run_screen.dart';
import '../ui/setup_screen.dart';

// --- Providers (no codegen). Tests override them with fakes. ---

final midiPortsProvider = Provider<MidiPortService>((ref) => MidiPortService());

/// Overridden in `main` once SharedPreferences is loaded.
final deviceSettingsProvider = Provider<DeviceSettings>(
    (ref) => throw UnimplementedError('deviceSettingsProvider: override it'));

/// Overridden in `main` with the app support directory.
final sessionStoreProvider = Provider<SessionStore>(
    (ref) => throw UnimplementedError('sessionStoreProvider: override it'));

/// Calibration and runs must share the same [ClickOut] (its constant error
/// is part of the calibrated latency).
final clickOutProvider = Provider<ClickOut>((ref) => SoloudClickOut());

/// Platform string written into session records.
final platformNameProvider = Provider<String>((ref) => Platform.isAndroid
    ? 'android'
    : Platform.isWindows
        ? 'windows'
        : Platform.isLinux
            ? 'linux'
            : Platform.operatingSystem);

typedef MidiDeviceRef = ({String id, String name});

/// The active MIDI input (one input → that one, several → the first); null
/// without any. Re-evaluated on every MIDI setup change.
final currentDeviceProvider = FutureProvider<MidiDeviceRef?>((ref) async {
  final ports = ref.watch(midiPortsProvider);
  final sub = ports.setupChanges.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  final devices = await ports.inputDevices();
  final id = chooseMidiDevice(devices);
  if (id == null) return null;
  final d = devices.firstWhere((d) => d.id == id);
  return (id: d.id, name: d.name);
});

/// Gate status of the newest saved session of an exercise; null if none.
final lastGateProvider =
    FutureProvider.family<GateStatus?, String>((ref, exerciseId) async {
  final recent =
      await ref.watch(sessionStoreProvider).recent(exerciseId, limit: 1);
  return recent.isEmpty ? null : analyzeSession(recent.first).gate.status;
});

/// Opens [deviceId] and wraps it in a NEW [MidiStrokeSource] with a NEW
/// timestamp mapper — call once per calibration and per run. Null when the
/// device cannot be opened.
typedef OpenStrokeSource = Future<StrokeSource?> Function(
    String deviceId, KitMapping mapping);

final openStrokeSourceProvider = Provider<OpenStrokeSource>((ref) {
  final ports = ref.watch(midiPortsProvider);
  return (deviceId, mapping) async {
    final port = await ports.open(deviceId);
    if (port == null) return null;
    return MidiStrokeSource(
      port: port,
      mapping: mapping,
      mapper: MidiTimestampMapper(midiTimestampUnitForPlatform(
        isAndroid: Platform.isAndroid,
        isLinux: Platform.isLinux,
        isWindows: Platform.isWindows,
      )),
    );
  };
});

// --- Router + theme ---

GoRouter buildRouter() => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'setup',
              builder: (_, __) => const SetupScreen(),
              routes: [
                GoRoute(
                    path: 'kit', builder: (_, __) => const KitLearnScreen()),
                GoRoute(
                    path: 'calibrate',
                    builder: (_, __) => const CalibrationScreen()),
              ],
            ),
            GoRoute(
              path: 'run/:exerciseId',
              redirect: (_, s) =>
                  exercises.any((e) => e.id == s.pathParameters['exerciseId'])
                      ? null
                      : '/',
              builder: (_, s) => RunScreen(
                  exercise: exerciseById(s.pathParameters['exerciseId']!)),
            ),
            GoRoute(
              path: 'feedback',
              redirect: (_, s) => s.extra is FeedbackArgs ? null : '/',
              builder: (_, s) => FeedbackScreen(args: s.extra! as FeedbackArgs),
            ),
          ],
        ),
      ],
    );

class DrumCoachApp extends StatefulWidget {
  const DrumCoachApp({super.key});

  @override
  State<DrumCoachApp> createState() => _DrumCoachAppState();
}

class _DrumCoachAppState extends State<DrumCoachApp> {
  final _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Drum Coach',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
  }
}
