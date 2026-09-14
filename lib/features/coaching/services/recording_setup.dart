import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Runtime query for Android audio capabilities (Brief Etappe 1, §1.1):
/// whether the device offers the UNPROCESSED audio source
/// (PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED).
class DeviceInfo {
  final String model;
  final String androidVersion;
  const DeviceInfo({required this.model, required this.androidVersion});
}

class AudioCapabilities {
  static const channel = MethodChannel('drum_coach/audio');

  static void Function()? _devicesChanged;

  /// Register (or clear with null) the listener for platform-side audio
  /// device changes — headphones plugged/unplugged. SoLoud does not reroute
  /// on its own: without reacting, the output stream dies on plug events
  /// and stays silent even after unplugging.
  static void onDevicesChanged(void Function()? callback) {
    _devicesChanged = callback;
    channel.setMethodCallHandler(callback == null
        ? null
        : (call) async {
            if (call.method == 'audioDevicesChanged') {
              _devicesChanged?.call();
            }
          });
  }

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

  /// Current headphone routing: `none` | `wired` | `bluetooth` — the
  /// Phase-2 session-header field the §0 survey found missing entirely.
  static Future<String> headphonesType() async {
    try {
      return await channel.invokeMethod<String>('headphonesType') ?? 'none';
    } on PlatformException {
      return 'none';
    } on MissingPluginException {
      return 'none';
    }
  }

  /// Id of the phone's built-in microphone (AudioDeviceInfo id), or null
  /// when it cannot be determined — used to pin the analysis recording to
  /// the built-in mic even while a headset is plugged in.
  static Future<String?> builtinMicId() async {
    try {
      return await channel.invokeMethod<String>('builtinMicId');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Device model and Android version for the session header.
  static Future<DeviceInfo> deviceInfo() async {
    try {
      final map = await channel.invokeMapMethod<String, String>('deviceInfo');
      return DeviceInfo(
        model: map?['model'] ?? 'unknown',
        androidVersion: map?['androidVersion'] ?? 'unknown',
      );
    } on PlatformException {
      return const DeviceInfo(model: 'unknown', androidVersion: 'unknown');
    } on MissingPluginException {
      return const DeviceInfo(model: 'unknown', androidVersion: 'unknown');
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
  final bool headphonesPlugged;

  const RecordingSetup._({
    required this.config,
    required this.unprocessedSupported,
    this.headphonesPlugged = false,
  });

  /// [headphonesPlugged] switches to the CAMCORDER source: with a headset
  /// plugged in, the default sources record through its inline mic, which
  /// hears the pad only faintly (A/B measurement 13.09.: stroke levels
  /// 0.8 without vs 0.2-0.4 with headphones). CAMCORDER always uses the
  /// phone's built-in mics — the established route for this. [builtinMicId]
  /// (explicit device pin) exists but is NOT used in production: pinning
  /// collapsed the levels on the S23 (see report, Nachtrag 13.09. (4)).
  static RecordingSetup choose({
    required bool unprocessedSupported,
    bool headphonesPlugged = false,
    String? builtinMicId,
  }) {
    return RecordingSetup._(
      unprocessedSupported: unprocessedSupported,
      headphonesPlugged: headphonesPlugged,
      config: RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        device: builtinMicId == null
            ? null
            : InputDevice(id: builtinMicId, label: 'builtin-mic'),
        androidConfig: AndroidRecordConfig(
          audioSource: headphonesPlugged
              ? AndroidAudioSource.camcorder
              : unprocessedSupported
                  ? AndroidAudioSource.unprocessed
                  : AndroidAudioSource.voiceRecognition,
        ),
      ),
    );
  }

  String get audioSourceName => headphonesPlugged
      ? 'camcorder'
      : unprocessedSupported
          ? 'unprocessed'
          : 'voice_recognition';

  Map<String, Object> describe() => {
        'audioSource': audioSourceName,
        'sampleRate': config.sampleRate,
        'unprocessedSupported': unprocessedSupported,
        'autoGain': config.autoGain,
        'echoCancel': config.echoCancel,
        'noiseSuppress': config.noiseSuppress,
        'inputDevice': config.device == null ? 'default' : 'builtin',
      };
}
