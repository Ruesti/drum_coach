import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The one place that knows whether we run on a desktop (Brief Etappe 2,
/// A.7). Tests inject [debugDesktopOverride]; production reads the host.
@visibleForTesting
bool? debugDesktopOverride;

bool get isDesktopPlatform =>
    debugDesktopOverride ??
    (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS));

/// Linux host (the MIDI timestamp unit depends on it). Override true reads
/// as Linux, false as Android.
bool get isLinuxPlatform =>
    debugDesktopOverride ?? (!kIsWeb && Platform.isLinux);

/// Android host. Override false reads as Android, true as not.
bool get isAndroidPlatform =>
    debugDesktopOverride == null
        ? (!kIsWeb && Platform.isAndroid)
        : !debugDesktopOverride!;

/// share_plus 13 throws `UnimplementedError` for file sharing on Linux:
/// on the desktop exports are saved to a file instead.
bool get fileShareAvailable => !isDesktopPlatform;

/// AI coaching needs the phone-only flow (API key, share sheet).
bool get aiCoachingAvailable => !isDesktopPlatform;

/// flutter_local_notifications 17 has no Linux/Windows implementation.
bool get localNotificationsAvailable => !isDesktopPlatform;

/// Desktop microphone capture (`record_linux`) is untested: off unless the
/// user picks "Mic" explicitly.
bool get micAllowedByDefault => !isDesktopPlatform;

/// Phone layout, centered, capped — no desktop redesign in Phase A.
const double desktopContentMaxWidth = 900;

Widget capContentWidth(BuildContext context, Widget? child) {
  if (!isDesktopPlatform || child == null) return child ?? const SizedBox();
  return ColoredBox(
    color: const Color(0xFF111111),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopContentMaxWidth),
        child: child,
      ),
    ),
  );
}
