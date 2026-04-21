import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles local push notifications for:
/// - Daily log reminder (every 3 hours from 6am till logged)
/// - Heat alerts (when temp crosses 35°C)
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      // Web doesn't support flutter_local_notifications
      _initialized = true;
      return;
    }
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: androidInit, iOS: iosInit));

    // Request permissions on Android 13+
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedule daily log reminders every 3 hours from 6am to 9pm
  /// Cancel all of today's if log is already added
  Future<void> scheduleDailyLogReminders() async {
    if (kIsWeb) return;
    await init();

    // Cancel previous
    await _plugin.cancelAll();

    // Schedule for 6am, 9am, 12pm, 3pm, 6pm, 9pm (every 3 hours)
    const hours = [9, 12, 15, 18, 21];
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < hours.length; i++) {
      final hour = hours[i];
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
      if (scheduled.isBefore(now)) continue; // don't schedule past times for today

      await _plugin.zonedSchedule(
        1000 + i,
        'Daily Log Reminder',
        'Add today\'s feed, eggs & deaths for your batches.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_log_channel',
            'Daily Log Reminders',
            channelDescription: 'Reminders to add daily farm log',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Cancel all daily log reminders (call after user adds today's log)
  Future<void> cancelDailyLogReminders() async {
    if (kIsWeb) return;
    await init();
    for (int i = 0; i < 5; i++) {
      await _plugin.cancel(1000 + i);
    }
  }

  /// Show an instant heat alert
  Future<void> showHeatAlert(double temp, {int severity = 0}) async {
    if (kIsWeb) return;
    await init();
    final title = severity >= 2 ? 'Critical Heat Alert!' : 'Heat Warning';
    final body = 'Temp is ${temp.toStringAsFixed(1)}°C at your farm. Provide cooling, water & ventilation.';
    await _plugin.show(
      2000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'heat_alert_channel',
          'Heat Alerts',
          channelDescription: 'High temperature warnings for farm',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// Test: trigger daily log reminder notification now
  Future<void> testDailyLogReminder() async {
    if (kIsWeb) return;
    await init();
    await _plugin.show(
      9001,
      'Daily Log Reminder',
      'Don\'t forget to add today\'s feed, eggs & deaths for your batches.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_log_channel',
          'Daily Log Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
