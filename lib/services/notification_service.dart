import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/local/settings_service.dart';

class NotificationService {
  NotificationService._();

  static const _practiceChannelId = 'drum_practice_reminder';
  static const _notificationId = 1;

  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );

    if (SettingsService.reminderEnabled) {
      await scheduleDailyReminder();
    }
  }

  static Future<void> scheduleDailyReminder() async {
    await _plugin.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      SettingsService.reminderHour,
      SettingsService.reminderMinute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId,
      'Time to practice! 🥁',
      'Keep your streak going — open DrumCoach',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _practiceChannelId,
          'Practice Reminders',
          channelDescription: 'Daily drum practice reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelReminder() => _plugin.cancel(_notificationId);
}
