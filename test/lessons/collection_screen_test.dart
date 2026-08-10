import 'package:drum_coach/features/lessons/collection_screen.dart';
import 'package:drum_coach/features/lessons/models/rudiment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows group headers and one tile per étude', (tester) async {
    // Enlarge the test viewport so the whole (long) collection list is laid
    // out without needing to scroll — ListView only builds elements for
    // items within the viewport.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CollectionScreen(collection: ExerciseCollection.rudimentEtudes),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Single Paradiddle'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
    expect(find.text('Rudiment-Étüden'), findsOneWidget);
  });

  testWidgets('groups the technique-studies collection', (tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CollectionScreen(collection: ExerciseCollection.techniqueStudies),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Akzent-Studien'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);
  });
}
