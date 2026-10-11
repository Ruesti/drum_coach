import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/practice/measurement_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('auto: midi when a device is there, else mic on the phone', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: true,
            isDesktop: false),
        MeasurementPlan.midi);
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: false,
            isDesktop: false),
        MeasurementPlan.mic);
  });

  test('auto on desktop without midi: nothing (mic untested there)', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.auto,
            midiDeviceAvailable: false,
            isDesktop: true),
        MeasurementPlan.none);
  });

  test('explicit mic on desktop is honoured', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.mic,
            midiDeviceAvailable: true,
            isDesktop: true),
        MeasurementPlan.mic);
  });

  test('midi without device: nothing; off: nothing', () {
    expect(
        planMeasurement(
            preference: MeasurementSource.midi,
            midiDeviceAvailable: false,
            isDesktop: false),
        MeasurementPlan.none);
    expect(
        planMeasurement(
            preference: MeasurementSource.off,
            midiDeviceAvailable: true,
            isDesktop: false),
        MeasurementPlan.none);
  });
}
