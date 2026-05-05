import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global callback — set this once from main and never reset
typedef PayloadCallback = void Function(String payload);
PayloadCallback? onNotificationTapped;

class NotificationService {
  static String? pendingPayload;

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      tz.initializeTimeZones();
      try {
        final timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        tz.setLocalLocation(tz.local);
      }

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
        onDidReceiveNotificationResponse: _onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
      );

      // Check if app was cold-launched via notification tap
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        pendingPayload = launchDetails?.notificationResponse?.payload;
        debugPrint('[NOTIF] Cold-launch payload stored: $pendingPayload');
      }
    } catch (e) {
      debugPrint('[NOTIF] Init error: $e');
    }
  }

  static void _onNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('[NOTIF] Tapped (foreground/background): $payload');
    if (payload == null) return;

    if (onNotificationTapped != null) {
      onNotificationTapped!(payload);
    } else {
      // Store for later pickup
      pendingPayload = payload;
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    pendingPayload = response.payload;
    debugPrint('[NOTIF] Background tap stored: ${response.payload}');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_channel',
          'Medication Reminders',
          importance: Importance.max,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint('[NOTIF] Scheduled id=$id at $scheduledTime payload=$payload');
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> testNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    await scheduleNotification(
      id: 9999,
      title: 'Medication Reminder',
      body: 'Tap here to mark your dose.',
      scheduledTime: scheduledTime,
      payload: '1:9999:Test Medication',
    );
    debugPrint('[NOTIF] Test notification scheduled for $scheduledTime');
  }
}
