import 'kit_instrument.dart';

/// Pure state of the learn step (Brief A.2): walks [KitInstrument.learnOrder],
/// every hit assigns the note to the current instrument (moving it away from
/// a previous owner, with a hint), skip keeps what is there.
class KitLearnSession {
  KitLearnSession({required KitMapping start}) : _mapping = start;

  KitMapping _mapping;
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

  void hit(int note) {
    final instrument = current;
    if (instrument == null) return;
    final previous = _mapping.instrumentFor(note);
    _hint = previous != null && previous != instrument
        ? 'Note $note moved from ${previous.label} to ${instrument.label}'
        : null;
    if (!_replacedThisStep) {
      _mapping = _mapping.remove(instrument);
      _replacedThisStep = true;
    }
    _mapping = _mapping.assign(instrument, note);
    _advance();
  }

  void skip() {
    if (done) return;
    _hint = null;
    _advance();
  }

  void back() {
    if (_index == 0) return;
    _index--;
    _replacedThisStep = true;
    _hint = null;
  }

  void _advance() {
    _index++;
    _replacedThisStep = false;
  }
}
