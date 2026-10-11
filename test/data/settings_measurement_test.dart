import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/coaching/midi/kit_instrument.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> init(Map<String, Object> initial) async {
    SharedPreferences.setMockInitialValues(initial);
    await SettingsService.init();
  }

  test('measurement source defaults to auto', () async {
    await init({});
    expect(SettingsService.measurementSource, MeasurementSource.auto);
    expect(SettingsService.micAnalysisEnabled, isTrue);
  });

  test('legacy "mic analysis off" migrates to off, never to auto', () async {
    await init({'mic_analysis_enabled': false});
    expect(SettingsService.measurementSource, MeasurementSource.off);
    expect(SettingsService.micAnalysisEnabled, isFalse);
  });

  test('legacy "mic analysis on" migrates to auto', () async {
    await init({'mic_analysis_enabled': true});
    expect(SettingsService.measurementSource, MeasurementSource.auto);
  });

  test('explicit source wins over the legacy key and round-trips', () async {
    await init({'mic_analysis_enabled': false});
    await SettingsService.setMeasurementSource(MeasurementSource.midi);
    expect(SettingsService.measurementSource, MeasurementSource.midi);
    expect(SettingsService.micAnalysisEnabled, isFalse);
    expect(MeasurementSource.midi.mayUseMidi, isTrue);
    expect(MeasurementSource.mic.mayUseMidi, isFalse);
  });

  test('kit mapping is stored per device and defaults to GM', () async {
    await init({});
    expect(SettingsService.kitMappingFor('Millenium').instrumentFor(38),
        KitInstrument.snare);
    await SettingsService.setKitMappingFor(
        'Millenium', KitMapping.gm().assign(KitInstrument.snare, 40));
    expect(SettingsService.kitMappingFor('Millenium').instrumentFor(40),
        KitInstrument.snare);
    expect(SettingsService.kitMappingFor('Other').instrumentFor(40), isNull);
  });

  test('midi latency per device, last device id, pad role', () async {
    await init({});
    expect(SettingsService.midiLatencyOffsetMsFor('Millenium'), isNull);
    await SettingsService.setMidiLatencyOffsetMsFor('Millenium', 18.5);
    expect(SettingsService.midiLatencyOffsetMsFor('Millenium'), 18.5);
    expect(SettingsService.midiLastDeviceId, isNull);
    await SettingsService.setMidiLastDeviceId('20:0');
    expect(SettingsService.midiLastDeviceId, '20:0');
    expect(SettingsService.padRoleInstrument, KitInstrument.snare);
    await SettingsService.setPadRoleInstrument(KitInstrument.tom1);
    expect(SettingsService.padRoleInstrument, KitInstrument.tom1);
  });
}
