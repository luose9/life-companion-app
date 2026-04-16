import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings, onDidReceiveNotificationResponse: _onNotificationResponse);

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // 删除所有旧版本频道（Android会缓存频道设置，不删无法更新）
      for (final old in [
        'life_companion_channel', 'life_companion_reminder',
        'lc_reminder_v2', 'lc_reminder_novib', 'lc_reminder_v2_novib',
        'lc_silent', 'lc_silent_novib',
        'lc_ringtone', 'lc_ringtone_novib',
        'lc_alarm', 'lc_alarm_novib',
      ]) {
        await androidPlugin?.deleteNotificationChannel(old);
      }

      // ===== v3 频道（全新ID，确保干净的配置） =====
      // 默认通知音
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'lc_v3_default',
          '日程提醒',
          description: '默认通知音提醒',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );
      // 系统铃声
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'lc_v3_ringtone',
          '系统铃声提醒',
          description: '使用系统铃声的提醒',
          importance: Importance.max,
          playSound: true,
          sound: const UriAndroidNotificationSound(_kRingtoneUri),
          enableVibration: true,
          showBadge: true,
        ),
      );
      // 闹钟铃声
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'lc_v3_alarm',
          '闹钟铃声提醒',
          description: '使用闹钟铃声的提醒',
          importance: Importance.max,
          playSound: true,
          sound: const UriAndroidNotificationSound(_kAlarmUri),
          enableVibration: true,
          showBadge: true,
        ),
      );
      // 静音
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'lc_v3_silent',
          '静音提醒',
          description: '无声音提醒',
          importance: Importance.max,
          playSound: false,
          enableVibration: true,
          showBadge: true,
        ),
      );

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    // handle notification tap if needed
  }

  // 系统可访问的声音 URI
  static const _kRingtoneUri = 'content://settings/system/ringtone';
  static const _kAlarmUri = 'content://settings/system/alarm_alert';

  AndroidNotificationDetails _androidDetailsForSound(String? soundPath, {bool enableVibration = true}) {
    if (soundPath == 'silent') {
      return const AndroidNotificationDetails(
        'lc_v3_silent', '静音提醒',
        channelDescription: '无声音提醒',
        importance: Importance.max,
        priority: Priority.high,
        playSound: false,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
      );
    }
    if (soundPath == 'ringtone') {
      return const AndroidNotificationDetails(
        'lc_v3_ringtone', '系统铃声提醒',
        channelDescription: '使用系统铃声的提醒',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: UriAndroidNotificationSound(_kRingtoneUri),
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
      );
    }
    if (soundPath == 'alarm') {
      return const AndroidNotificationDetails(
        'lc_v3_alarm', '闹钟铃声提醒',
        channelDescription: '使用闹钟铃声的提醒',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: UriAndroidNotificationSound(_kAlarmUri),
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.alarm,
      );
    }
    // 默认系统通知音
    return const AndroidNotificationDetails(
      'lc_v3_default', '日程提醒',
      channelDescription: '默认通知音提醒',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
    );
  }

  Future<void> ensureCustomChannel(String? soundPath) async {
    // v3 频道已在 init() 中创建，无需动态创建
  }

  Future<void> scheduleNotification(int id, String title, String body, DateTime when, {String? soundPath, bool enableVibration = true}) async {
    try {
      if (soundPath != null && soundPath != 'silent') await ensureCustomChannel(soundPath);
      final details = NotificationDetails(android: _androidDetailsForSound(soundPath, enableVibration: enableVibration));
      // 如果时间已过，立即显示通知
      if (when.isBefore(DateTime.now())) {
        await _plugin.show(id, title, body, details);
        return;
      }
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(when, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleNotification error: $e');
    }
  }

  Future<void> scheduleRecurring(int id, String title, String body, DateTime firstInstance, String repeatRule, {String? soundPath, bool enableVibration = true}) async {
    try {
      if (soundPath != null && soundPath != 'silent') await ensureCustomChannel(soundPath);
      final details = NotificationDetails(android: _androidDetailsForSound(soundPath, enableVibration: enableVibration));

      DateTimeComponents? components;
      if (repeatRule == 'daily') components = DateTimeComponents.time;
      if (repeatRule == 'weekly') components = DateTimeComponents.dayOfWeekAndTime;

      if (components != null) {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(firstInstance, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.wallClockTime,
          matchDateTimeComponents: components,
        );
      } else {
        await scheduleNotification(id, title, body, firstInstance);
      }
    } catch (e) {
      debugPrint('scheduleRecurring error: $e');
    }
  }

  // 立即显示一条测试通知（用于调试）
  Future<void> showNow(String title, String body) async {
    final details = NotificationDetails(android: _androidDetailsForSound(null));
    await _plugin.show(99999, title, body, details);
  }

  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('cancel notification error: $e');
    }
  }
}

Future<void> initNotificationPlugin() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
  await NotificationService.instance.init();
}
