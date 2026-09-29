import 'package:drum_coach/features/lessons/lessons_screen.dart';
import 'package:drum_coach/features/practice/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
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

  testWidgets('the library opens with a photo header and the title on it',
      (tester) async {
    // 29.09. (Uli): "die Library-Seite braucht Bild" — a borderless photo
    // header, about a third of the screen, title on it, filters below.
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LessonsScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Library'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image).first);
    expect(practiceBackdrops, contains((image.image as AssetImage).assetName));
    final size = tester.getSize(find.byType(Image).first);
    expect(size.width, 360);
    expect(size.height, closeTo(780 * 0.32, 1));
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>));
    expect(region.value.statusBarIconBrightness, Brightness.light);
    // The list still works below the header.
    expect(find.text('Single Stroke Roll'), findsOneWidget);
  });
}
