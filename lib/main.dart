import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/local/isar_service.dart';
import 'data/local/settings_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    // Large output buffer (~186 ms at 44.1 kHz): the click is a native loop,
    // so output latency is irrelevant (it sits in the calibration value) —
    // robustness against CPU spikes is what matters. Device test: recording
    // running in parallel caused ~7 audible drop-outs per 5 min with the
    // default 2048-sample buffer.
    SoLoud.instance.init(bufferSize: 8192),
    IsarService.init(),
    SettingsService.init(),
  ]);
  await NotificationService.init();
  runApp(
    const ProviderScope(
      child: DrumCoachApp(),
    ),
  );
}

class DrumCoachApp extends StatelessWidget {
  const DrumCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DrumCoach',
      theme: drumCoachTheme,
      routerConfig: router,
    );
  }
}
