import '../../../app/platform_support.dart';

export '../../../app/platform_support.dart' show UncappedContent;

/// From this width on the guided screens use the wide (desktop) layout.
bool guidedWide(double width) => width >= 1000;

/// Content width limit of the guided screens on desktop.
const double guidedMaxWidth = uncappedContentMaxWidth;
