import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Tempo step of the guided screens' +/- buttons and keys; Shift doubles it.
const int guidedTempoStep = 4;

/// Desktop keys of the guided screens (preview and practice): Space
/// [primary], ↑/↓ and +/− tempo by [guidedTempoStep] (Shift: twice that),
/// T teacher, P play along, Esc [leave].
Map<ShortcutActivator, VoidCallback> guidedShortcuts({
  required VoidCallback primary,
  required ValueChanged<int> bumpBpm,
  required VoidCallback toggleTeacher,
  required VoidCallback togglePlayAlong,
  required VoidCallback leave,
}) {
  const s = guidedTempoStep;
  return {
    const SingleActivator(LogicalKeyboardKey.space): primary,
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => bumpBpm(s),
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
        bumpBpm(2 * s),
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => bumpBpm(-s),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
        bumpBpm(-2 * s),
    const SingleActivator(LogicalKeyboardKey.equal): () => bumpBpm(s),
    const SingleActivator(LogicalKeyboardKey.equal, shift: true): () =>
        bumpBpm(s),
    const SingleActivator(LogicalKeyboardKey.add): () => bumpBpm(s),
    const SingleActivator(LogicalKeyboardKey.numpadAdd): () => bumpBpm(s),
    const SingleActivator(LogicalKeyboardKey.minus): () => bumpBpm(-s),
    const SingleActivator(LogicalKeyboardKey.numpadSubtract): () => bumpBpm(-s),
    const SingleActivator(LogicalKeyboardKey.keyT): toggleTeacher,
    const SingleActivator(LogicalKeyboardKey.keyP): togglePlayAlong,
    const SingleActivator(LogicalKeyboardKey.escape): leave,
  };
}
