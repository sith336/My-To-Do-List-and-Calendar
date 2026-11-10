import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'task.dart';

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool? _permissionGranted;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _initialize() async {
    if (_initialized || !_isSupported) return;
    tz_data.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    await _initialize();
    if (defaultTargetPlatform == TargetPlatform.android) {
      _permissionGranted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } else {
      _permissionGranted =
          await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return _permissionGranted!;
  }

  Future<bool> scheduleTask(TodoTask task) async {
    if (!_isSupported || task.isComplete || !task.dateTime.isAfter(DateTime.now())) {
      return false;
    }
    await _initialize();
    final permission = _permissionGranted ?? await requestPermission();
    if (!permission) return false;

    await _plugin.zonedSchedule(
      id: _notificationId(task.id),
      title: 'Task due',
      body: task.title,
      scheduledDate: tz.TZDateTime.from(task.dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_due',
          'Task reminders',
          channelDescription: 'Notifications when a task is due.',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return true;
  }

  Future<void> cancelTask(TodoTask task) async {
    if (!_isSupported) return;
    await _initialize();
    await _plugin.cancel(id: _notificationId(task.id));
  }

  int _notificationId(String id) {
    final numericId = int.tryParse(id);
    if (numericId != null) return numericId & 0x7fffffff;
    return id.codeUnits.fold<int>(
      0,
      (hash, character) => (hash * 31 + character) & 0x7fffffff,
    );
  }
}
