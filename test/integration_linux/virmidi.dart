/// Card number of the ALSA virmidi rawmidi port among [deviceNames]
/// (`Virtual Raw MIDI <card>-0`), null when none is loaded. The card number
/// differs per machine (0 on the NUC, 1 on the laptop).
int? virmidiCard(List<String> deviceNames) {
  final re = RegExp(r'^Virtual Raw MIDI (\d+)-0$');
  for (final n in deviceNames) {
    final m = re.firstMatch(n);
    if (m != null) return int.parse(m.group(1)!);
  }
  return null;
}
