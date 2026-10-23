import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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

/// Number of [UncappedContent] widgets currently counting as on screen.
/// The builder in [capContentWidth] wraps the Navigator, so a route cannot
/// reach it directly: it registers here and the cap widens while the count
/// is > 0. The cap listens at the render level (no rebuild), so the count
/// may change at any point of a frame, also during build.
final ValueNotifier<int> uncappedContentCount = ValueNotifier<int>(0);

/// Route-level opt-out from the 900 px cap: while its route is the current
/// one and entering or shown (animation forward/completed), the content may
/// grow to [uncappedContentMaxWidth]. It stops counting the moment the
/// route starts to leave (pop: animation reverse) or another route is
/// pushed on top, so the page that comes back is laid out capped from the
/// first frame of the transition. Without a [ModalRoute] (tests) it counts
/// while mounted.
class UncappedContent extends StatefulWidget {
  const UncappedContent({super.key, required this.child});
  final Widget child;

  @override
  State<UncappedContent> createState() => _UncappedContentState();
}

class _UncappedContentState extends State<UncappedContent> {
  ModalRoute<Object?>? _route;
  Animation<double>? _animation;
  bool _counted = false;
  bool _active = true;

  bool get _wanted {
    if (!_active) return false;
    final route = _route;
    if (route == null) return true;
    if (!route.isCurrent) return false;
    final status = route.animation?.status ?? AnimationStatus.completed;
    return status == AnimationStatus.forward ||
        status == AnimationStatus.completed;
  }

  void _sync() {
    final want = _wanted;
    if (want == _counted) return;
    _counted = want;
    uncappedContentCount.value += want ? 1 : -1;
  }

  void _onStatus(AnimationStatus _) => _sync();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depends on the route's status: rebuilt when isCurrent changes.
    _route = ModalRoute.of(context);
    final animation = _route?.animation;
    if (!identical(animation, _animation)) {
      _animation?.removeStatusListener(_onStatus);
      _animation = animation?..addStatusListener(_onStatus);
    }
    _sync();
  }

  @override
  void deactivate() {
    _active = false;
    _sync();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
    _sync();
  }

  @override
  void dispose() {
    _animation?.removeStatusListener(_onStatus);
    _active = false;
    _sync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-checked on every rebuild (isCurrent changes rebuild us).
    _sync();
    return widget.child;
  }
}

double get _capMaxWidth => uncappedContentCount.value > 0
    ? uncappedContentMaxWidth
    : desktopContentMaxWidth;

/// Width cap that follows [uncappedContentCount] by relayout only: a change
/// in the middle of a build (a route leaving) applies in the same frame.
class _ContentCap extends SingleChildRenderObjectWidget {
  const _ContentCap({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderContentCap();
}

class _RenderContentCap extends RenderConstrainedBox {
  _RenderContentCap()
      : super(additionalConstraints: BoxConstraints(maxWidth: _capMaxWidth));

  void _update() =>
      additionalConstraints = BoxConstraints(maxWidth: _capMaxWidth);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    uncappedContentCount.addListener(_update);
    _update();
  }

  @override
  void detach() {
    uncappedContentCount.removeListener(_update);
    super.detach();
  }
}

Widget capContentWidth(BuildContext context, Widget? child) {
  if (!isDesktopPlatform || child == null) return child ?? const SizedBox();
  return ColoredBox(
    color: const Color(0xFF111111),
    child: Center(child: _ContentCap(child: child)),
  );
}
