import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/practice_session.dart';
import 'models/rudiment_progress.dart';

class IsarService {
  static late Isar _isar;
  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [PracticeSessionSchema, RudimentProgressSchema],
      directory: dir.path,
    );
  }
}
