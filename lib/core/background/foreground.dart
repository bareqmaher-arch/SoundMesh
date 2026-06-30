import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../call/call_task_handler.dart';

/// إعداد خدمة المقدمة التي تُبقي الشبكة والصوت حيّين أثناء السكون/الإغلاق،
/// وتستضيف معالج الاتصال الوارد في عزلة مستقلّة.
class Foreground {
  Foreground._();

  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'takiwaki_channel',
        channelName: 'TakiWaki',
        channelDescription: 'يُبقي القناة اللاسلكية نشطة في الخلفية',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // حدث دوري كل ثانيتين لبثّ الحضور وتحديث قائمة المتصلين من الخلفية.
        eventAction: ForegroundTaskEventAction.repeat(2000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWifiLock: true,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> requestPermissions() async {
    final notif = await FlutterForegroundTask.checkNotificationPermission();
    if (notif != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      serviceId: 7700,
      notificationTitle: 'TakiWaki نشط',
      notificationText: 'القناة اللاسلكية متصلة',
      callback: startCallCallback,
    );
  }

  static Future<void> stop() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  /// حفظ الملف الشخصي ليقرأه معالج الخلفية ويبثّه كحضور.
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    await FlutterForegroundTask.saveData(
      key: BackgroundHandler.profileKey,
      value: jsonEncode(profile),
    );
    // إعلام المعالج بالتحديث الفوري إن كان يعمل.
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask(
          jsonEncode({'cmd': 'profile', 'profile': profile}));
    }
  }

  static Future<void> updateText(String text) async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'TakiWaki نشط',
        notificationText: text,
      );
    }
  }
}
