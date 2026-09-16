import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'data/local/isar_service.dart';
import 'data/local/settings_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts ship as assets (assets/google_fonts/); never fetch at runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await Future.wait([
    // Default buffer size on purpose: raising it to 8192 slowed playback by
    // ~24% on-device (flutter_soloud/miniaudio side effect) — do NOT try to
    // fight recording-induced drop-outs that way again.
    SoLoud.instance.init(),
    IsarService.init(),
    SettingsService.init(),
  ]);
  // Reminders are a convenience — a plugin failure here must never keep the
  // app stuck on the splash screen (seen in release: R8 + notifications).
  try {
    await NotificationService.init().timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint('NotificationService.init skipped: $e');
  }
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
