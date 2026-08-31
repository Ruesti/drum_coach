import 'package:drum_coach/app/platform_support.dart';
import 'package:drum_coach/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Binding exists but no platform-channel handlers are registered, so any
  // real flutter_local_notifications call would throw MissingPluginException.
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugIsDesktopOverride = null);

  test('init() is a no-op on desktop (no plugin channel call)', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.init(), completes);
  });

  test('scheduleDailyReminder() is a no-op on desktop', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.scheduleDailyReminder(), completes);
  });

  test('cancelReminder() is a no-op on desktop', () {
    debugIsDesktopOverride = true;
    expect(NotificationService.cancelReminder(), completes);
  });
}
