import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'models/clean_tempo.dart';
import 'models/practice_session.dart';
import 'models/rudiment_progress.dart';
import 'models/session_log.dart';

class IsarService {
  static late Isar _isar;
  static Isar get instance => _isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        PracticeSessionSchema,
        RudimentProgressSchema,
        // Unused since the Trainingsraum replaced the training program
        // (31.10.); stays registered so existing databases open unchanged.
        CleanTempoSchema,
        SessionLogSchema,
      ],
      directory: dir.path,
    );
  }
}
