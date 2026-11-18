import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/timer_mode.dart';

const kSessionEndNotificationId = 4242;

/// OS notifications: when a session starts we schedule an exact alarm for
/// its end time, so the alert fires even if the app is backgrounded.
/// Pausing / resetting cancels the pending alarm.
class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }

    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    _ready = true;
  }

  Future<bool> requestPermission() async {
    try {
      if (!_ready) await init();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final impl =
            _plugin.resolvePlatformImplementation<IOSFlutterLocalNotificationsPlugin>();
        final granted = await impl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        final impl =
            _plugin.resolvePlatformImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await impl?.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final impl =
            _plugin.resolvePlatformImplementation<AndroidFlutterLocalNotificationsPlugin>();
        return await impl?.areNotificationsEnabled() ?? false;
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS status is not directly readable via the plugin; assume granted
        // after an explicit request. The settings sheet lets users re-request.
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> scheduleSessionEnd({
    required TimerMode mode,
    required Duration duration,
  }) async {
    try {
      if (!_ready) await init();
      final when = tz.TZDateTime.from(
        DateTime.now().add(duration),
        tz.local,
      );
      final isFocus = mode == TimerMode.focus;
      await _plugin.zonedSchedule(
        kSessionEndNotificationId,
        isFocus ? 'Focus session complete' : 'Break is over - back to it',
        isFocus ? 'Nice hop. Time for a breather.' : 'Ribbit. Next focus session is ready.',
        when,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'toadtimer_sessions',
            'Session alerts',
            channelDescription: 'Fires when a focus or break session ends',
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            presentBadge: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Schedule failed: $e');
    }
  }

  Future<void> cancelScheduled() async {
    try {
      await _plugin.cancel(kSessionEndNotificationId);
    } catch (_) {}
  }
}
