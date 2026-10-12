import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Desktop keys for the practice screen (Brief Etappe 2, A.7).
Map<ShortcutActivator, VoidCallback> practiceShortcuts({
  required VoidCallback toggle,
  required ValueChanged<int> bumpBpm,
  required VoidCallback leave,
}) =>
    {
      const SingleActivator(LogicalKeyboardKey.space): toggle,
      const SingleActivator(LogicalKeyboardKey.arrowUp): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
          bumpBpm(5),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () => bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
          bumpBpm(-5),
      const SingleActivator(LogicalKeyboardKey.equal): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.add): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.numpadAdd): () => bumpBpm(1),
      const SingleActivator(LogicalKeyboardKey.minus): () => bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
          bumpBpm(-1),
      const SingleActivator(LogicalKeyboardKey.escape): leave,
    };
