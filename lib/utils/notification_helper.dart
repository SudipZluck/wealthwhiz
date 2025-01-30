import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';
import '../constants/constants.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  static Future<void> showBudgetAlert({
    required String title,
    required String body,
    required int id,
  }) async {
    if (!AppConstants.enablePushNotifications) return;

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription: 'Notifications for budget limits',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> showBillReminder({
    required String title,
    required String body,
    required int id,
    required DateTime scheduledDate,
  }) async {
    if (!AppConstants.enablePushNotifications) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bill_reminders',
          'Bill Reminders',
          channelDescription: 'Reminders for upcoming bills',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showSavingsGoalUpdate({
    required String title,
    required String body,
    required int id,
  }) async {
    if (!AppConstants.enablePushNotifications) return;

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'savings_goals',
          'Savings Goals',
          channelDescription: 'Updates for savings goals progress',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> scheduleWeeklyDigest({
    required int id,
    required DateTime scheduledDate,
  }) async {
    if (!AppConstants.enablePushNotifications) return;

    await _notifications.zonedSchedule(
      id,
      'Weekly Financial Summary',
      'Check out your spending patterns and budget status for this week.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_digest',
          'Weekly Digest',
          channelDescription: 'Weekly financial summaries and insights',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> showTransactionAlert({
    required String title,
    required String body,
    required int id,
  }) async {
    if (!AppConstants.enablePushNotifications) return;

    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'transactions',
          'Transactions',
          channelDescription: 'Notifications for new transactions',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
