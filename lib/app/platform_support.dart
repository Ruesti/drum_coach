import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

/// Test-only override. When non-null, [isDesktopPlatform] returns this value
/// instead of probing the real OS. Reset to null in tearDown.
@visibleForTesting
bool? debugIsDesktopOverride;

/// True on the three Flutter desktop targets. False on web and mobile.
bool get isDesktopPlatform {
  final override = debugIsDesktopOverride;
  if (override != null) return override;
  if (kIsWeb) return false;
  return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
}

/// AI coaching (mic analysis + Claude API) ships mobile-only in Phase 1.
bool get aiCoachingAvailable => !isDesktopPlatform;
