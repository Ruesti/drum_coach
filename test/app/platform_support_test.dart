import 'package:drum_coach/app/platform_support.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => debugDesktopOverride = null);

  test('desktop override drives every derived flag', () {
    debugDesktopOverride = true;
    expect(isDesktopPlatform, isTrue);
    expect(aiCoachingAvailable, isFalse);
    expect(localNotificationsAvailable, isFalse);
    expect(micAllowedByDefault, isFalse);
    expect(isLinuxPlatform, isTrue);
    expect(isAndroidPlatform, isFalse);
    expect(fileShareAvailable, isFalse);
    debugDesktopOverride = false;
    expect(isDesktopPlatform, isFalse);
    expect(aiCoachingAvailable, isTrue);
    expect(localNotificationsAvailable, isTrue);
    expect(micAllowedByDefault, isTrue);
    expect(isLinuxPlatform, isFalse);
    expect(isAndroidPlatform, isTrue);
    expect(fileShareAvailable, isTrue);
  });

  test('without override the host decides (test host is desktop)', () {
    // flutter test runs on a desktop OS; the real app on the phone sees
    // false. This only pins that the getter reads the platform.
    expect(isDesktopPlatform, isTrue);
    // The test host is Linux (this NUC), never Android.
    expect(isLinuxPlatform, isTrue);
    expect(isAndroidPlatform, isFalse);
  });
}
