import 'package:drum_coach/features/coaching/services/recording_setup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordingSetup.choose', () {
    test('uses UNPROCESSED when the device supports it', () {
      final s = RecordingSetup.choose(unprocessedSupported: true);
      expect(s.config.androidConfig.audioSource, AndroidAudioSource.unprocessed);
      expect(s.audioSourceName, 'unprocessed');
    });

    test('falls back to VOICE_RECOGNITION without UNPROCESSED', () {
      final s = RecordingSetup.choose(unprocessedSupported: false);
      expect(s.config.androidConfig.audioSource,
          AndroidAudioSource.voiceRecognition);
      expect(s.audioSourceName, 'voice_recognition');
    });

    test('explicitly requests AGC, NS and AEC off on both paths', () {
      for (final supported in [true, false]) {
        final s = RecordingSetup.choose(unprocessedSupported: supported);
        expect(s.config.autoGain, isFalse);
        expect(s.config.echoCancel, isFalse);
        expect(s.config.noiseSuppress, isFalse);
      }
    });

    test('records PCM16 mono at 16 kHz', () {
      final s = RecordingSetup.choose(unprocessedSupported: true);
      expect(s.config.encoder, AudioEncoder.pcm16bits);
      expect(s.config.sampleRate, 16000);
      expect(s.config.numChannels, 1);
    });

    test('describes itself for the session header (Phase 2)', () {
      final s = RecordingSetup.choose(unprocessedSupported: false);
      expect(s.describe(), {
        'audioSource': 'voice_recognition',
        'sampleRate': 16000,
        'unprocessedSupported': false,
        'autoGain': false,
        'echoCancel': false,
        'noiseSuppress': false,
      });
    });
  });

  group('AudioCapabilities.isUnprocessedSupported', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, null);
    });

    test('returns the platform answer', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, (call) async {
        expect(call.method, 'isUnprocessedSupported');
        return true;
      });
      expect(await AudioCapabilities.isUnprocessedSupported(), isTrue);
    });

    test('answers false when the platform side is missing', () async {
      expect(await AudioCapabilities.isUnprocessedSupported(), isFalse);
    });
  });

  group('AudioCapabilities.headphonesType', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, null);
    });

    test('returns the platform answer', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, (call) async {
        expect(call.method, 'headphonesType');
        return 'wired';
      });
      expect(await AudioCapabilities.headphonesType(), 'wired');
    });

    test('answers none when the platform side is missing', () async {
      expect(await AudioCapabilities.headphonesType(), 'none');
    });
  });

  group('AudioCapabilities.onDevicesChanged', () {
    test('invokes the registered callback when the platform notifies', () async {
      var calls = 0;
      AudioCapabilities.onDevicesChanged(() => calls++);
      addTearDown(() => AudioCapabilities.onDevicesChanged(null));

      final envelope = const StandardMethodCodec()
          .encodeMethodCall(const MethodCall('audioDevicesChanged'));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
              AudioCapabilities.channel.name, envelope, (_) {});
      expect(calls, 1,
          reason: 'headphone plug/unplug must reach the audio engine');
    });
  });

  group('AudioCapabilities.deviceInfo', () {
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, null);
    });

    test('returns model and android version', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(AudioCapabilities.channel, (call) async {
        expect(call.method, 'deviceInfo');
        return {'model': 'SM-S918B', 'androidVersion': '14'};
      });
      final info = await AudioCapabilities.deviceInfo();
      expect(info.model, 'SM-S918B');
      expect(info.androidVersion, '14');
    });

    test('falls back to unknown when the platform side is missing', () async {
      final info = await AudioCapabilities.deviceInfo();
      expect(info.model, 'unknown');
      expect(info.androidVersion, 'unknown');
    });
  });
}
