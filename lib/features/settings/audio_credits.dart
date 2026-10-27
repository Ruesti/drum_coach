/// Who made a sound the app ships, where it comes from and its licence.
/// Shown on Settings → Credits; `assets/audio/CREDITS.md` says the same
/// (test/features/settings/credits_test.dart compares both and checks that
/// every shipped sound file is covered).
class AudioCredit {
  const AudioCredit({
    required this.title,
    required this.author,
    required this.source,
    required this.licence,
    required this.licenceUrl,
    required this.files,
    this.note = '',
  });

  final String title;
  final String author;

  /// Where the recording was downloaded.
  final String source;
  final String licence;
  final String licenceUrl;

  /// Asset paths; one ending in `/` covers every file of that folder.
  final List<String> files;

  /// What was changed (CC BY asks for it).
  final String note;

  bool covers(String path) =>
      files.any((f) => f.endsWith('/') ? path.startsWith(f) : path == f);
}

const audioCredits = <AudioCredit>[
  AudioCredit(
    title: 'DRSKit 2.1 (drum kit of the guided exercises)',
    author: 'the DrumGizmo team (Deva and Lars Muldjord); '
        'drums by Jes Eiler, DRSDrums',
    source: 'https://drumgizmo.org/wiki/doku.php?id=kits:drskit',
    licence: 'CC BY 4.0',
    licenceUrl: 'https://creativecommons.org/licenses/by/4.0/',
    note: 'Mixed down to mono from the close, overhead and room microphones, '
        'trimmed, shortened with a fade-out and level-matched; three '
        'velocity takes per instrument.',
    files: [
      'assets/audio/kit_kick_soft.wav',
      'assets/audio/kit_kick_medium.wav',
      'assets/audio/kit_kick_hard.wav',
      'assets/audio/kit_snare_soft.wav',
      'assets/audio/kit_snare_medium.wav',
      'assets/audio/kit_snare_hard.wav',
      'assets/audio/kit_rim_soft.wav',
      'assets/audio/kit_rim_medium.wav',
      'assets/audio/kit_rim_hard.wav',
      'assets/audio/kit_hihat_closed_soft.wav',
      'assets/audio/kit_hihat_closed_medium.wav',
      'assets/audio/kit_hihat_closed_hard.wav',
      'assets/audio/kit_hihat_open_soft.wav',
      'assets/audio/kit_hihat_open_medium.wav',
      'assets/audio/kit_hihat_open_hard.wav',
      'assets/audio/kit_hihat_pedal_soft.wav',
      'assets/audio/kit_hihat_pedal_medium.wav',
      'assets/audio/kit_hihat_pedal_hard.wav',
      'assets/audio/kit_tom_high_soft.wav',
      'assets/audio/kit_tom_high_medium.wav',
      'assets/audio/kit_tom_high_hard.wav',
      'assets/audio/kit_tom_low_soft.wav',
      'assets/audio/kit_tom_low_medium.wav',
      'assets/audio/kit_tom_low_hard.wav',
      'assets/audio/kit_tom_floor_soft.wav',
      'assets/audio/kit_tom_floor_medium.wav',
      'assets/audio/kit_tom_floor_hard.wav',
      'assets/audio/kit_crash_soft.wav',
      'assets/audio/kit_crash_medium.wav',
      'assets/audio/kit_crash_hard.wav',
      'assets/audio/kit_ride_soft.wav',
      'assets/audio/kit_ride_medium.wav',
      'assets/audio/kit_ride_hard.wav',
      'assets/audio/kit_ride_bell_soft.wav',
      'assets/audio/kit_ride_bell_medium.wav',
      'assets/audio/kit_ride_bell_hard.wav',
    ],
  ),
  AudioCredit(
    title: 'Acoustic snare (pad exercises)',
    author: 'KEVOY',
    source: 'https://freesound.org/people/KEVOY/sounds/82249/',
    licence: 'CC0 1.0',
    licenceUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    note: 'Converted to WAV, encoder delay removed.',
    files: ['assets/audio/snare.wav'],
  ),
  AudioCredit(
    title: 'Coach voice (Piper voice en_GB cori, high)',
    author: 'Bryce Beattie (voice model), from LibriVox recordings',
    source:
        'https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_GB/cori/high',
    licence: 'Public domain',
    licenceUrl:
        'https://huggingface.co/rhasspy/piper-voices/blob/main/en/en_GB/cori/high/MODEL_CARD',
    note: 'Spoken clips generated offline with Piper.',
    files: ['assets/voice/'],
  ),
];
