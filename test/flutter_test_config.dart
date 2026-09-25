import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test file: fonts come from the bundled assets
/// (assets/google_fonts/), never from the network — otherwise google_fonts
/// fails tests asynchronously on machines without its font cache.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
