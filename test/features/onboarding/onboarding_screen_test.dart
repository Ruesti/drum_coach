import 'package:drum_coach/data/local/settings_service.dart';
import 'package:drum_coach/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets('welcome is a full-screen drummer photo with the form on top',
      (tester) async {
    // Decided 27.09.: the emoji drum looked generated → a photo; then "full
    // screen": the photo fills the whole screen, text and form lie on it.
    await tester.pumpWidget(
        MaterialApp(home: OnboardingScreen(onComplete: () {})));
    await tester.pump();
    expect(find.text('🥁'), findsNothing);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/illustrations/today/done.jpg');
    // Fills the screen (360×780 dp).
    final rect = tester.getRect(find.byType(Image));
    expect(rect.width, 360);
    expect(rect.height, 780);
    expect(find.text('Welcome to DrumCoach'), findsOneWidget);
    expect(find.text("Let's go!"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
