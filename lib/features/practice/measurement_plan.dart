import '../../data/local/settings_service.dart';

enum MeasurementPlan { midi, mic, none }

/// Which source the practice screen opens (Brief A.6/A.7): MIDI whenever
/// allowed and present; the microphone where allowed — on the desktop only
/// on explicit request.
MeasurementPlan planMeasurement({
  required MeasurementSource preference,
  required bool midiDeviceAvailable,
  required bool isDesktop,
}) {
  if (preference.mayUseMidi && midiDeviceAvailable) return MeasurementPlan.midi;
  if (preference == MeasurementSource.mic) return MeasurementPlan.mic;
  if (preference == MeasurementSource.auto && !isDesktop) {
    return MeasurementPlan.mic;
  }
  return MeasurementPlan.none;
}
