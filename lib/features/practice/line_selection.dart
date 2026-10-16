import '../lessons/models/sheet_plan.dart';

/// Which sheet lines (0-based, in play order) the practice screen opens
/// with. `?lines=all` takes every line, `?lines=1,3,5` those (1-based,
/// order kept, garbage and duplicates dropped). Without a usable list,
/// `?line=N` (1-based alias; out of range = line 1), else the remembered
/// line (clamped), else line 1. Never an error.
List<int> initialLineSelection({
  required int lineCount,
  String? linesParam,
  int? lineParam,
  int? rememberedLine,
}) {
  final raw = linesParam?.trim() ?? '';
  if (raw == 'all') return [for (var i = 0; i < lineCount; i++) i];
  final picked = <int>[];
  for (final part in raw.split(',')) {
    final n = int.tryParse(part.trim());
    if (n == null || n < 1 || n > lineCount) continue;
    if (!picked.contains(n - 1)) picked.add(n - 1);
  }
  if (picked.isNotEmpty) return picked;
  if (lineParam != null) {
    return [lineParam >= 1 && lineParam <= lineCount ? lineParam - 1 : 0];
  }
  final r = rememberedLine;
  if (r != null && r >= 0 && r < lineCount) return [r];
  return const [0];
}

/// The `?lines=` value for a selection: 1-based, comma separated.
String linesQuery(List<int> zeroBased) => zeroBased.map((i) => i + 1).join(',');

/// The line bar's label: "Line 3 of 8" for one line, "Step 2 of 4 ·
/// Line 5 · 1/2" inside a sequence ([line], [step], [pass] 0-based).
String lineNavLabel({
  required int line,
  required int lineCount,
  required int step,
  required int steps,
  required int pass,
  required int repeats,
}) =>
    steps <= 1
        ? 'Line ${line + 1} of $lineCount'
        : 'Step ${step + 1} of $steps · Line ${line + 1} · '
            '${pass + 1}/$repeats';

/// Session-log fields for the played unit: the 1-based line for one line;
/// for a sequence no line but its selection ([linesQuery] form).
({int? line, String? lines, String mode}) sessionLogSheetFields(
        SheetPlan plan) =>
    plan.isSequence
        ? (line: null, lines: linesQuery(plan.selection), mode: 'sequence')
        : (line: plan.lineIndex + 1, lines: null, mode: 'line');
