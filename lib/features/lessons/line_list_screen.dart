import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/design_tokens.dart';
import '../../data/local/settings_service.dart';
import '../../shared/widgets/notation_staff_widget.dart';
import '../../shared/widgets/sheet_geometry.dart';
import '../learning/suggested_bpm_provider.dart';
import '../practice/line_selection.dart';
import 'lesson_detail_screen.dart';
import 'lessons_provider.dart';
import 'models/rudiment.dart';

/// One exercise's lines as cards (Zeilen statt Blatt, 16.10.): tap a line
/// to practise it, select several to play them as a sequence, or play all.
/// The last practised line carries an accent frame.
class LineListScreen extends ConsumerStatefulWidget {
  final String rudimentId;
  const LineListScreen({super.key, required this.rudimentId});

  @override
  ConsumerState<LineListScreen> createState() => _LineListScreenState();
}

class _LineListScreenState extends ConsumerState<LineListScreen> {
  bool _selecting = false;
  final Set<int> _selected = {};

  // Geometry once per content width (clef line 0: a card drawn alone takes
  // its height from its own layout, only the row pitch is shared).
  double? _geoWidth;
  SheetGeometry? _geo;

  SheetGeometry _geometryFor(Rudiment r, double width) {
    if (_geo == null || _geoWidth != width) {
      _geoWidth = width;
      _geo = computeSheetGeometry(r, width, showCounts: false);
    }
    return _geo!;
  }

  Future<void> _play(String lines) async {
    final id = widget.rudimentId;
    final bpm = await ref.read(suggestedBpmProvider(id).future);
    if (!mounted) return;
    // Coming back from practice shows the normal list, not the selection.
    if (_selecting) _leaveSelection();
    await context.push('/practice/$id?lines=$lines&bpm=$bpm');
    // The practice screen remembers the line it played: re-read the mark.
    if (mounted) setState(() {});
  }

  // Unticking the last line leaves selection mode (no dead "0 selected").
  void _toggle(int i) => setState(() {
        if (!_selected.remove(i)) {
          _selected.add(i);
        } else if (_selected.isEmpty) {
          _selecting = false;
        }
      });

  void _leaveSelection() => setState(() {
        _selecting = false;
        _selected.clear();
      });

  @override
  Widget build(BuildContext context) {
    final rudiment = ref.watch(rudimentByIdProvider(widget.rudimentId));
    final last = SettingsService.lastLineFor(rudiment.id);
    final n = _selected.length;
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selecting) _leaveSelection();
      },
      child: Scaffold(
        appBar: _selecting
            ? AppBar(
                leading: IconButton(
                  key: const ValueKey('selection-close'),
                  icon: const Icon(Icons.close),
                  onPressed: _leaveSelection,
                ),
                title: Text('$n selected'),
              )
            : AppBar(
                title: Text(
                  rudiment.name,
                  maxLines: rudiment.name.length > 24 ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  TextButton(
                    key: const ValueKey('select-mode'),
                    onPressed: () => setState(() => _selecting = true),
                    child: const Text('Select'),
                  ),
                  IconButton(
                    key: const ValueKey('lesson-info'),
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'About this exercise',
                    // A plain Navigator push: /exercise lives outside the
                    // bottom-nav shell, pushing /library/:id from here hits
                    // the duplicate-page-key trap (as in the practice
                    // screen).
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            LessonDetailScreen(rudimentId: rudiment.id),
                      ),
                    ),
                  ),
                ],
              ),
        body: LayoutBuilder(builder: (context, c) {
          final geo = _geometryFor(
              rudiment, c.maxWidth - 32 - 2 * SheetStaffWidget.hPad);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              ExerciseMetaRow(rudiment: rudiment),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  key: const ValueKey('play-all'),
                  onPressed: () => _play('all'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play all'),
                ),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < rudiment.sheet.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _framed(
                    // No accent frame while selecting: it would read as a
                    // selection.
                    marked: !_selecting && i == last,
                    child: _card(rudiment, geo, i),
                  ),
                ),
            ],
          );
        }),
        bottomNavigationBar: _selecting
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: FilledButton(
                    key: const ValueKey('play-selected'),
                    // Always in list order, whatever order they were ticked.
                    onPressed: n == 0
                        ? null
                        : () => _play(linesQuery(_selected.toList()..sort())),
                    child: Text(n == 1 ? 'Play 1 line' : 'Play $n lines'),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _framed({required bool marked, required Widget child}) => marked
      ? Container(
          key: const ValueKey('line-card-last'),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.accent, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: child,
        )
      : child;

  Widget _card(Rudiment rudiment, SheetGeometry geo, int i) {
    final staff = SheetStaffWidget(
      rudiment: rudiment,
      geometry: geo,
      onlyLine: i,
      showCounts: false,
      showSticking: true,
    );
    return GestureDetector(
      key: Key('line-card-${i + 1}'),
      behavior: HitTestBehavior.opaque,
      onTap: _selecting ? () => _toggle(i) : () => _play(linesQuery([i])),
      onLongPress: _selecting
          ? null
          : () => setState(() {
                _selecting = true;
                _selected.add(i);
              }),
      child: _selecting
          ? Row(
              children: [
                Checkbox(
                  key: ValueKey('line-check-${i + 1}'),
                  value: _selected.contains(i),
                  onChanged: (_) => _toggle(i),
                ),
                Expanded(child: staff),
              ],
            )
          : staff,
    );
  }
}
