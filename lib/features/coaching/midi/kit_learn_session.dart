import 'kit_instrument.dart';

/// Pure state of the learn step (Brief A.2): walks [KitInstrument.learnOrder].
/// Hits assign zones to the current instrument — the first hit of a step
/// replaces the instrument's old notes, further hits add zones (head, rim,
/// edge …); a note used elsewhere moves here, with a hint. The user moves on
/// with [next]; [skip] keeps what is there.
class KitLearnSession {
  KitLearnSession({required KitMapping start})
      : _mapping = start,
        _stepStart = start;

  KitMapping _mapping;

  /// The mapping when the current step was entered — what [skip] keeps.
  KitMapping _stepStart;
  int _index = 0;
  String? _hint;

  /// Assigning the first note of a step replaces the instrument's old
  /// notes; further hits on the same step add zones.
  bool _replacedThisStep = false;

  List<KitInstrument> get _order => KitInstrument.learnOrder;

  KitInstrument? get current => done ? null : _order[_index];
  int get index => _index;
  int get total => _order.length;
  KitMapping get mapping => _mapping;
  bool get done => _index >= _order.length;
  String? get hint => _hint;

  /// Notes assigned to the current instrument (for the step text).
  Set<int> get currentNotes =>
      current == null ? const {} : (_mapping.notes[current!] ?? const {});

  void hit(int note) {
    final instrument = current;
    if (instrument == null) return;
    // The same zone hit twice in a step adds nothing.
    if (_replacedThisStep && currentNotes.contains(note)) return;
    final previous = _mapping.instrumentFor(note);
    _hint = previous != null && previous != instrument
        ? 'Note $note moved from ${previous.label} to ${instrument.label}'
        : null;
    if (!_replacedThisStep) {
      _mapping = _mapping.remove(instrument);
      _replacedThisStep = true;
    }
    _mapping = _mapping.assign(instrument, note);
  }

  /// Done with the current instrument: on to the next one.
  void next() {
    if (done) return;
    _hint = null;
    _advance();
  }

  /// Leaves the current instrument as it was when the step began: hits of
  /// this step are undone, then on to the next one.
  void skip() {
    if (done) return;
    _mapping = _stepStart;
    next();
  }

  void back() {
    if (_index == 0) return;
    _index--;
    _replacedThisStep = true;
    _stepStart = _mapping;
    _hint = null;
  }

  void _advance() {
    _index++;
    _replacedThisStep = false;
    _stepStart = _mapping;
  }
}
