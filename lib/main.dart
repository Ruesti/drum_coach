import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'run/device_settings.dart';
import 'run/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final dir = await getApplicationSupportDirectory();
  runApp(ProviderScope(
    overrides: [
      deviceSettingsProvider.overrideWithValue(DeviceSettings(prefs)),
      sessionStoreProvider.overrideWithValue(SessionStore(dir)),
    ],
    child: const DrumCoachApp(),
  ));
}
