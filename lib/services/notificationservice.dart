import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcherplaystore');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    tz.initializeTimeZones();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  NotificationDetails getPlatformChannelSpecifics() {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel id',
      'channel name',
      icon: "@drawable/ic_launcherplaystore",
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    return platformChannelSpecifics;
  }

  Future<void> showNotification(String title, String body) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1)),
        getPlatformChannelSpecifics(),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future scheduleNotification(
      {int id = 0,
      required String title,
      required String? body,
      required DateTime scheduledNotificationDateTime}) async {
    return flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledNotificationDateTime, tz.local),
        const NotificationDetails(),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  Future<void> onSelectNotification(String? payload) async {
    return;
  }
}
