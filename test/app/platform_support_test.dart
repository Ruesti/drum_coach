// test/app/platform_support_test.dart
import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugIsDesktopOverride = null);

  test('override true → desktop, coaching unavailable', () {
    debugIsDesktopOverride = true;
    expect(isDesktopPlatform, isTrue);
    expect(aiCoachingAvailable, isFalse);
  });

  test('override false → not desktop, coaching available', () {
    debugIsDesktopOverride = false;
    expect(isDesktopPlatform, isFalse);
    expect(aiCoachingAvailable, isTrue);
  });
}
