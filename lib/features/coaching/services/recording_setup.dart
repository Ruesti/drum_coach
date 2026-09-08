import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Runtime query for Android audio capabilities (Brief Etappe 1, §1.1):
/// whether the device offers the UNPROCESSED audio source
/// (PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED).
class AudioCapabilities {
  static const channel = MethodChannel('drum_coach/audio');

  static Future<bool> isUnprocessedSupported() async {
    try {
      return await channel.invokeMethod<bool>('isUnprocessedSupported') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

/// The raw recording path of §1.1: UNPROCESSED when available, otherwise
/// VOICE_RECOGNITION with AGC/NS/AEC explicitly requested off. No automatic
/// gain anywhere. [describe] feeds the session header (Phase 2) and the
/// phase report.
class RecordingSetup {
  static const int sampleRate = 16000;

  final RecordConfig config;
  final bool unprocessedSupported;

  const RecordingSetup._({
    required this.config,
    required this.unprocessedSupported,
  });

  static RecordingSetup choose({required bool unprocessedSupported}) {
    return RecordingSetup._(
      unprocessedSupported: unprocessedSupported,
      config: RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        androidConfig: AndroidRecordConfig(
          audioSource: unprocessedSupported
              ? AndroidAudioSource.unprocessed
              : AndroidAudioSource.voiceRecognition,
        ),
      ),
    );
  }

  String get audioSourceName =>
      unprocessedSupported ? 'unprocessed' : 'voice_recognition';

  Map<String, Object> describe() => {
        'audioSource': audioSourceName,
        'sampleRate': config.sampleRate,
        'unprocessedSupported': unprocessedSupported,
        'autoGain': config.autoGain,
        'echoCancel': config.echoCancel,
        'noiseSuppress': config.noiseSuppress,
      };
}
