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

/// Width limit while an [UncappedContent] route is on screen (guided
/// exercises, desktop-first layout).
const double uncappedContentMaxWidth = 1440;

/// Number of [UncappedContent] widgets currently mounted. The builder in
/// [capContentWidth] wraps the Navigator, so a route cannot reach it
/// directly: it registers here and the cap widens while the count is > 0.
final ValueNotifier<int> uncappedContentCount = ValueNotifier<int>(0);

/// Route-level opt-out from the 900 px cap: while mounted, the content may
/// grow to [uncappedContentMaxWidth].
class UncappedContent extends StatefulWidget {
  const UncappedContent({super.key, required this.child});
  final Widget child;

  @override
  State<UncappedContent> createState() => _UncappedContentState();
}

class _UncappedContentState extends State<UncappedContent> {
  // Changes are deferred to after the frame: notifying the cap widget in the
  // middle of build/unmount would mark it dirty while the tree is locked.
  void _bump(int d) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      uncappedContentCount.value += d;
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void initState() {
    super.initState();
    _bump(1);
  }

  @override
  void dispose() {
    _bump(-1);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget capContentWidth(BuildContext context, Widget? child) {
  if (!isDesktopPlatform || child == null) return child ?? const SizedBox();
  return ColoredBox(
    color: const Color(0xFF111111),
    child: Center(
      child: ValueListenableBuilder<int>(
        valueListenable: uncappedContentCount,
        // Same widget structure either way: the Navigator keeps its state.
        child: child,
        builder: (_, count, child) => ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                count > 0 ? uncappedContentMaxWidth : desktopContentMaxWidth,
          ),
          child: child,
        ),
      ),
    ),
  );
}
