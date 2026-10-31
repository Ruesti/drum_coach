part of 'notation_staff_widget.dart';

/// Staff step of an instrument's notehead (Brief B.2): half line-gaps above
/// the middle line. Lines are −4, −2, 0, 2, 4; spaces the odd steps; −5
/// sits under the first line, 5 above the fifth, 6 is the first ledger
/// line above the staff.
int kitStaffStep(KitInstrument i) => switch (i) {
      KitInstrument.hiHatPedal => -5,
      KitInstrument.kick => -3,
      KitInstrument.floorTom2 => -2,
      KitInstrument.floorTom1 => -1,
      KitInstrument.snare || KitInstrument.snareRim => 1,
      KitInstrument.tom2 => 2,
      KitInstrument.tom1 => 3,
      KitInstrument.ride || KitInstrument.rideBell => 4,
      KitInstrument.hiHatClosed || KitInstrument.hiHatOpen => 5,
      KitInstrument.crash1 ||
      KitInstrument.crash2 ||
      KitInstrument.china ||
      KitInstrument.splash =>
        6,
      KitInstrument.pad || KitInstrument.unknown => 0,
    };

/// Notehead shape per instrument (Brief B.2): drums normal, cymbals x,
/// ride bell a diamond, china a circled x, splash a small x.
enum KitHeadShape { normal, x, diamond, circleX, xSmall }

KitHeadShape kitHeadShape(KitInstrument i) => switch (i) {
      KitInstrument.snareRim ||
      KitInstrument.hiHatClosed ||
      KitInstrument.hiHatOpen ||
      KitInstrument.hiHatPedal ||
      KitInstrument.ride ||
      KitInstrument.crash1 ||
      KitInstrument.crash2 =>
        KitHeadShape.x,
      KitInstrument.rideBell => KitHeadShape.diamond,
      KitInstrument.china => KitHeadShape.circleX,
      KitInstrument.splash => KitHeadShape.xSmall,
      _ => KitHeadShape.normal,
    };

/// Kit rows: two layers on one staff — hands (stems up, beams above) and
/// feet (stems down, beams below); every column one stem per layer, heads
/// on their instrument's step. Beams, tuplet brackets and rests come from
/// the layer tracks (`KitLineLayout`), the heads from the columns.
extension _KitPainting on _StaffPainter {
  double _yOfStep(double staffY, int step) =>
      staffY - step * _StaffPainter._lineGap / 2;

  void _paintKitRow(Canvas canvas, int row, double y0, double staffY) {
    final kit = _kit!;
    final stemTopY = y0 + _stemTopY;
    final stemBottomY = y0 + _StaffPainter._stemBottomY;
    final handsBeamed =
        _paintLayerBeams(canvas, kit.hands, row, stemTopY, up: true);
    final feetBeamed =
        _paintLayerBeams(canvas, kit.feet, row, stemBottomY, up: false);
    _paintTuplets(canvas, kit.hands, row, y0 + _accentY);
    // With foot letters the feet bracket sits in the band between the feet
    // beams (lowest beam at stemBottomY, 3 px thick) and the letter row
    // (11 px bold centred at _footLetterY), so neither touches the numeral.
    _paintTuplets(canvas, kit.feet, row,
        footLetters ? stemBottomY + 6 : stemBottomY + 14);

    // Rests of the hands layer only — feet rests are left out, as drum
    // charts do.
    for (final p in kit.hands.placements) {
      if (p.row != row || !p.isRest) continue;
      _drawRest(canvas, Offset(p.xCenter, staffY), p.resolved.value,
          _dim(_StaffPainter._ghostColor));
    }

    for (var c = 0; c < kit.columns.length; c++) {
      final col = kit.columns[c];
      if (kit.rowOfTick(col.tick) != row) continue;
      final x = kit.xOfTick(col.tick);
      // Counts per column, so a beat only the feet play is counted too.
      final count = kitCountLabels?[c];
      if (count != null) {
        _drawText(canvas, count, Offset(x, y0 + _countY),
            _dim(_StaffPainter._letterColor), 10);
      }
      final active = col.tick == _boxTick;
      _paintLayerColumn(canvas, col.hands.toList(), x, y0, staffY,
          up: true,
          stemEndY: stemTopY,
          layout: kit.hands,
          index: kit.handsIndexOfTick[col.tick],
          beamed: handsBeamed,
          active: active,
          letterHand: kit.handLetters[col.tick]);
      _paintLayerColumn(canvas, col.feet.toList(), x, y0, staffY,
          up: false,
          stemEndY: stemBottomY,
          layout: kit.feet,
          index: kit.feetIndexOfTick[col.tick],
          beamed: feetBeamed,
          active: active,
          letterHand: kit.footLetters[col.tick]);
    }
  }

  /// Beam runs of one layer; returns the placement indices that are beamed.
  Set<int> _paintLayerBeams(
      Canvas canvas, StaffLayout layout, int row, double beamY,
      {required bool up}) {
    final beamed = <int>{};
    final dx = up ? _StaffPainter._headRx - 0.5 : -_StaffPainter._headRx + 0.5;
    for (final bg in layout.beams) {
      if (bg.row != row || bg.beamCount == 0) continue;
      final x0 = layout.placements[bg.startIndex].xCenter + dx;
      final x1 = layout.placements[bg.endIndex].xCenter + dx;
      final paint = Paint()
        ..color = _dim(_StaffPainter._inkColor)
        ..strokeWidth = 3.0;
      for (var b = 0; b < bg.beamCount; b++) {
        final y = up ? beamY + b * 5.0 : beamY - b * 5.0;
        canvas.drawLine(Offset(x0, y), Offset(x1, y), paint);
      }
      for (var idx = bg.startIndex; idx <= bg.endIndex; idx++) {
        beamed.add(idx);
      }
    }
    return beamed;
  }

  void _paintTuplets(Canvas canvas, StaffLayout layout, int row, double y) {
    for (final bg in layout.beams) {
      if (bg.row != row || bg.tuplet == Tuplet.none) continue;
      final x0 = layout.placements[bg.startIndex].xCenter;
      final x1 = layout.placements[bg.endIndex].xCenter;
      final label = bg.tuplet == Tuplet.sextuplet ? '6' : '3';
      _drawTupletBracket(
          canvas, x0, x1, y, label, _dim(_StaffPainter._inkColor));
    }
  }

  /// One layer at one column: heads on their steps, one stem from the
  /// farthest head to the layer's stem end, flag when not beamed, accent,
  /// ghost parentheses, dot and letter ([letterHand]: the sticking letter or
  /// foot side, null = none; see `kitLettersOf`).
  void _paintLayerColumn(
      Canvas canvas, List<KitNote> notes, double x, double y0, double staffY,
      {required bool up,
      required double stemEndY,
      required StaffLayout layout,
      required int? index,
      required Set<int> beamed,
      required bool active,
      required Hand? letterHand}) {
    if (notes.isEmpty || index == null) return;
    final resolved = layout.placements[index].resolved;
    var topY = double.infinity;
    var bottomY = double.negativeInfinity;
    final anyAccent = notes.any((n) => n.beat.isAccent);
    for (final n in notes) {
      final step = kitStaffStep(n.voice.instrument);
      final y = _yOfStep(staffY, step);
      if (y < topY) topY = y;
      if (y > bottomY) bottomY = y;
      final color = _dim(n.beat.isAccent
          ? _accentColor
          : n.beat.isGhost
              ? _StaffPainter._ghostColor
              : _StaffPainter._inkColor);
      if (step >= 6) _drawLedger(canvas, x, _yOfStep(staffY, 6));
      if (n.beat.graces.isNotEmpty) {
        _drawGraces(canvas, n.beat.graces, x, y, stemEndY,
            _dim(_StaffPainter._ghostColor));
      }
      _drawKitHead(
          canvas, Offset(x, y), kitHeadShape(n.voice.instrument), color,
          ghost: n.beat.isGhost, active: active);
      if (n.voice.instrument == KitInstrument.hiHatOpen) {
        _drawText(canvas, 'o', Offset(x, y - 10), color, 9, bold: true);
      }
      if (n.beat.isGhost) {
        final ink = _dim(_StaffPainter._ghostColor);
        _drawText(
            canvas, '(', Offset(x - _StaffPainter._headRx - 4, y), ink, 14);
        _drawText(
            canvas, ')', Offset(x + _StaffPainter._headRx + 4, y), ink, 14);
      }
      if (resolved.dotted) _drawDot(canvas, Offset(x, y), color);
    }

    final stemColor = _dim(anyAccent ? _accentColor : _StaffPainter._inkColor);
    if (resolved.value != NoteValue.whole) {
      final stemX = up
          ? x + _StaffPainter._headRx - 0.6
          : x - _StaffPainter._headRx + 0.6;
      canvas.drawLine(
          Offset(stemX, up ? bottomY - 1 : topY + 1),
          Offset(stemX, stemEndY),
          Paint()
            ..color = stemColor
            ..strokeWidth = 1.6);
      final bc = beamCountFor(resolved.value);
      if (bc > 0 && !beamed.contains(index)) {
        if (up) {
          _drawFlags(canvas, stemX, stemEndY, stemColor, bc);
        } else {
          _drawFlagsDown(canvas, stemX, stemEndY, stemColor, bc);
        }
      }
    }
    if (anyAccent) {
      _drawAccent(canvas, Offset(x, up ? y0 + _accentY : stemEndY + 8),
          _dim(_accentColor));
    }
    if (!up) {
      // Foot side (double bass): only for a foot voice that alternates
      // sides in the line (`KitLineLayout.footLetters`), under the stems.
      final side = switch (letterHand) {
        Hand.right => 'R',
        Hand.left => 'L',
        null => null,
      };
      if (footLetters && showSticking && side != null) {
        _drawText(canvas, side, Offset(x, y0 + _StaffPainter._footLetterY),
            _dim(_StaffPainter._letterColor), 11,
            bold: true);
      }
      return;
    }
    final letter = switch (letterHand) {
      Hand.right => 'R',
      Hand.left => 'L',
      null => null,
    };
    if (showSticking && letter != null) {
      _drawText(canvas, letter, Offset(x, y0 + _letterY),
          _dim(_StaffPainter._letterColor), 12,
          bold: true);
    }
  }

  void _drawKitHead(Canvas canvas, Offset c, KitHeadShape shape, Color color,
      {required bool ghost, required bool active}) {
    switch (shape) {
      case KitHeadShape.normal:
        _drawHead(canvas, c, color,
            ghost: ghost, active: active, value: NoteValue.quarter);
        return;
      case KitHeadShape.x:
        _drawGlyph(canvas, _Smufl.noteheadXBlack, c, color);
      case KitHeadShape.xSmall:
        _drawGlyph(canvas, _Smufl.noteheadXBlack, c, color, emScale: 3);
      case KitHeadShape.diamond:
        _drawGlyph(canvas, _Smufl.noteheadDiamondBlack, c, color);
      case KitHeadShape.circleX:
        _drawGlyph(canvas, _Smufl.noteheadCircleX, c, color);
    }
    if (active) {
      canvas.drawOval(
          Rect.fromCenter(
                  center: c,
                  width: _StaffPainter._headRx * 2,
                  height: _StaffPainter._headRy * 2)
              .inflate(2.5),
          Paint()
            ..color = _StaffPainter._cursorLine
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  /// Short ledger line through a head above the staff (crash, china, splash).
  void _drawLedger(Canvas canvas, double x, double y) {
    canvas.drawLine(
        Offset(x - 9, y),
        Offset(x + 9, y),
        Paint()
          ..color = _dim(_StaffPainter._staffColor)
          ..strokeWidth = 1.0);
  }

  void _drawFlagsDown(Canvas canvas, double stemX, double stemBottomY,
      Color color, int beamCount) {
    final glyph = switch (beamCount) {
      1 => _Smufl.flag8Down,
      2 => _Smufl.flag16Down,
      _ => _Smufl.flag32Down,
    };
    // The down flag hangs up from the stem's bottom end; nudge until it
    // sits on the stem end in the golden (start at 0).
    _drawGlyph(canvas, glyph, Offset(stemX + 3, stemBottomY), color,
        dyStaffSpaces: 0);
  }
}
