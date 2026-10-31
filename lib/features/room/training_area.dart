/// The training room's areas: every exercise belongs to exactly one.
/// Enum names are mirrored by the catalog tool (`tool/katalog/blatt.py`).
enum TrainingArea {
  handTechnique('Hand technique'),
  rudiments('Rudiments'),
  feet('Feet'),
  coordination('Coordination'),
  groove('Grooves'),
  metal('Metal'),
  fills('Fills');

  final String label;
  const TrainingArea(this.label);
}
