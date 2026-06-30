import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/protocol/packet.dart';
import 'call_protocol.dart';

/// نقطة الدخول لمعالج الخلفية — يجب أن تكون دالة عليا موسومة vm:entry-point.
@pragma('vm:entry-point')
void startCallCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundHandler());
}

/// يعمل في عزلة مستقلّة يبقيها الـ Foreground Service حيّة حتى عند إغلاق
/// واجهة التطبيق. مسؤول عن:
///  - بثّ حضور الجهاز (beacon) باستمرار كي يبقى مرئياً للآخرين.
///  - اكتشاف الأقران وبناء قائمة المتصلين وإرسالها للواجهة.
///  - استقبال إشارات الاتصال وإظهار إشعار اتصال وارد بملء الشاشة (فوق القفل).
class BackgroundHandler extends TaskHandler {
  static const String profileKey = 'tw_profile';
  static const String incomingCallKey = 'tw_incoming_call';
  static const int incomingCallNotifId = 8800;
  static const String callChannelId = 'takiwaki_incoming_calls';
  // قناة منفصلة صامتة تماماً للإيقاظ الخاص بالبثّ المباشر (بلا أي نغمة).
  // v2: أهمية max لتفتح التطبيق على الأجهزة المتشدّدة (سامسونج) دون نغمة.
  static const String broadcastChannelId = 'takiwaki_broadcast_silent_v2';

  RawDatagramSocket? _discoverySocket;
  RawDatagramSocket? _signalSocket;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Map<String, dynamic> _profile = {};
  final Map<String, Map<String, dynamic>> _peers = {};

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('TW-BG: onStart معالج الخلفية بدأ');
    await _loadProfile();
    await _initNotifications();
    await _bindDiscovery();
    await _bindSignaling();
    _sendBeacon();
  }

  Future<void> _loadProfile() async {
    try {
      final raw = await FlutterForegroundTask.getData<String>(key: profileKey);
      if (raw != null) _profile = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
  }

  Future<void> _initNotifications() async {
    try {
      const androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await _notifications.initialize(
        const InitializationSettings(android: androidInit),
      );
      // قناة عالية الأهمية لمكالمات الوارد (رنين النظام + اهتزاز + ملء الشاشة).
      const channel = AndroidNotificationChannel(
        callChannelId,
        'مكالمات واردة',
        description: 'إشعارات الاتصال الوارد عبر TakiWaki',
        importance: Importance.max,
        playSound: true,
        sound: UriAndroidNotificationSound('content://settings/system/ringtone'),
        enableVibration: true,
      );
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(channel);
      // قناة الإيقاظ الصامت — أهمية max (لتفتح التطبيق فوق القفل حتى على
      // سامسونج) لكن بلا صوت ولا اهتزاز.
      const broadcastChannel = AndroidNotificationChannel(
        broadcastChannelId,
        'بثّ صوتي مباشر',
        description: 'إيقاظ صامت للبثّ المباشر عبر TakiWaki',
        importance: Importance.max,
        playSound: false,
        enableVibration: false,
      );
      await androidImpl?.createNotificationChannel(broadcastChannel);
      print('TW-BG: تهيئة الإشعارات نجحت');
    } catch (e) {
      print('TW-BG: فشل تهيئة الإشعارات: $e');
    }
  }

  Future<void> _bindDiscovery() async {
    try {
      _discoverySocket?.close();
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        DiscoveryPorts.discoveryPort,
        reuseAddress: true,
      );
      _discoverySocket!
        ..broadcastEnabled = true
        ..multicastHops = 4;
      try {
        _discoverySocket!
            .joinMulticast(InternetAddress(DiscoveryPorts.multicastGroup));
      } catch (_) {}
      // عند أي خطأ/إغلاق (انقطاع شبكة) نُغلق السوكِت ونُفرّغ المرجع ليُعاد الربط.
      _discoverySocket!.listen(
        _onDiscovery,
        onError: (_) {
          _discoverySocket?.close();
          _discoverySocket = null;
        },
        onDone: () {
          _discoverySocket?.close();
          _discoverySocket = null;
        },
        cancelOnError: true,
      );
      print('TW-BG: ربط منفذ الاكتشاف ${DiscoveryPorts.discoveryPort} نجح');
    } catch (e) {
      _discoverySocket = null;
      print('TW-BG: فشل ربط منفذ الاكتشاف: $e');
    }
  }

  Future<void> _bindSignaling() async {
    try {
      _signalSocket?.close();
      _signalSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        CallSignal.signalingPort,
        reuseAddress: true,
      );
      _signalSocket!.listen(
        _onSignal,
        onError: (_) {
          _signalSocket?.close();
          _signalSocket = null;
        },
        onDone: () {
          _signalSocket?.close();
          _signalSocket = null;
        },
        cancelOnError: true,
      );
      print('TW-BG: ربط منفذ الإشارات ${CallSignal.signalingPort} نجح');
    } catch (e) {
      _signalSocket = null;
      print('TW-BG: فشل ربط منفذ الإشارات: $e');
    }
  }

  /// يعيد ربط أي سوكِت ماتت (مثلاً بعد انقطاع/عودة WiFi).
  void _ensureSockets() {
    if (_discoverySocket == null) _bindDiscovery();
    if (_signalSocket == null) _bindSignaling();
  }

  void _onDiscovery(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _discoverySocket?.receive();
    if (dg == null) return;
    final map = ControlPacket.tryDecode(dg.data);
    if (map == null) return;
    final type = map['t'] as int?;
    final id = map['id'] as String?;
    if (id == null || id == _profile['id']) return;

    if (type == PacketType.beacon) {
      _peers[id] = {
        'id': id,
        'name': map['name'],
        'phone': map['phone'],
        'avatarHash': map['avatarHash'],
        'defaultAvatar': map['defaultAvatar'] ?? 0,
        'address': dg.address.address,
        'tcpPort': map['tcpPort'] ?? 45455,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      };
    } else if (type == PacketType.leave) {
      _peers.remove(id);
    }
  }

  void _onSignal(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _signalSocket?.receive();
    if (dg == null) return;
    final signal = CallSignal.decode(dg.data, senderAddress: dg.address.address);
    if (signal == null) return;
    print('TW-BG: وصلت إشارة "${signal.type}" من ${dg.address.address}');
    switch (signal.type) {
      case CallSignal.typeCall:
        _showIncoming(signal);
        break;
      case CallSignal.typeCancel:
        _endIncoming();
        break;
      case CallSignal.typeWake:
        _wakeForBroadcast();
        break;
    }
  }

  DateTime _lastWake = DateTime.fromMillisecondsSinceEpoch(0);

  /// إيقاظ صامت للتطبيق ليستقبل البثّ المباشر (بلا رنين ولا شاشة اتصال).
  Future<void> _wakeForBroadcast() async {
    // تفادي الإيقاظ المتكرّر خلال فترة قصيرة.
    if (DateTime.now().difference(_lastWake) < const Duration(seconds: 8)) {
      FlutterForegroundTask.launchApp();
      return;
    }
    _lastWake = DateTime.now();
    const androidDetails = AndroidNotificationDetails(
      broadcastChannelId, // قناة صامتة مستقلّة — بلا أي نغمة
      'بثّ صوتي مباشر',
      channelDescription: 'إيقاظ صامت للبثّ المباشر عبر TakiWaki',
      importance: Importance.max,
      priority: Priority.max,
      // category=call + أهمية max يجعل سامسونج يفتح التطبيق فوق القفل (كالمكالمة).
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      playSound: false,
      enableVibration: false,
      onlyAlertOnce: true,
      autoCancel: true,
      timeoutAfter: 4000,
    );
    try {
      await _notifications.show(
        incomingCallNotifId + 1,
        'بثّ صوتي مباشر',
        'انضممت للبثّ — استمع الآن',
        const NotificationDetails(android: androidDetails),
        payload: 'broadcast',
      );
    } catch (_) {}
    FlutterForegroundTask.launchApp();
  }

  Future<void> _showIncoming(CallSignal s) async {
    // حفظ معلومات الاتصال كي تقرأها الواجهة عند فتحها.
    final info = {
      'callId': s.callId,
      'fromId': s.fromId,
      'fromName': s.fromName,
      'fromAddress': s.fromAddress,
      'group': s.group,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      await FlutterForegroundTask.saveData(
          key: incomingCallKey, value: jsonEncode(info));
    } catch (_) {}

    // إعلام الواجهة فوراً إن كانت مفتوحة.
    FlutterForegroundTask.sendDataToMain(jsonEncode({'incomingCall': info}));

    // إشعار بملء الشاشة يوقظ الجهاز فوق القفل ويفتح شاشة الرنين.
    final androidDetails = AndroidNotificationDetails(
      callChannelId,
      'مكالمات واردة',
      channelDescription: 'إشعارات الاتصال الوارد عبر TakiWaki',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      playSound: true,
      sound: const UriAndroidNotificationSound(
          'content://settings/system/ringtone'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 800, 1000, 800]),
      // FLAG_INSISTENT=4: يكرّر الرنين/الاهتزاز حتى يُلغى الإشعار (رنين متواصل).
      additionalFlags: Int32List.fromList([4]),
      // إيقاف الرنين تلقائياً بعد 45 ثانية إن لم يُردّ.
      timeoutAfter: 45000,
      ticker: 'اتصال وارد',
    );
    try {
      await _notifications.show(
        incomingCallNotifId,
        '${s.fromName} يتصل بك',
        s.group ? 'اتصال جماعي — اضغط للرد' : 'اتصال خاص — اضغط للرد',
        NotificationDetails(android: androidDetails),
        payload: 'incoming_call',
      );
      print('TW-BG: تم عرض إشعار الاتصال بملء الشاشة');
    } catch (e) {
      print('TW-BG: فشل عرض الإشعار: $e');
    }
    // إيقاظ التطبيق لعرض شاشة الرنين.
    FlutterForegroundTask.launchApp('/incoming-call');
  }

  Future<void> _endIncoming() async {
    try {
      await FlutterForegroundTask.removeData(key: incomingCallKey);
      await _notifications.cancel(incomingCallNotifId);
    } catch (_) {}
    FlutterForegroundTask.sendDataToMain(jsonEncode({'callCancelled': true}));
  }

  void _sendBeacon() {
    final socket = _discoverySocket;
    if (socket == null || _profile['id'] == null) return;
    final payload = ControlPacket.beacon(_profile, 45455);
    try {
      socket.send(payload, InternetAddress(DiscoveryPorts.multicastGroup),
          DiscoveryPorts.discoveryPort);
      socket.send(payload, InternetAddress('255.255.255.255'),
          DiscoveryPorts.discoveryPort);
    } catch (_) {
      // فشل الإرسال (انقطاع شبكة) — نُغلق ونُفرّغ ليُعاد الربط في الدورة التالية.
      _discoverySocket?.close();
      _discoverySocket = null;
    }
  }

  void _sweepAndPublish() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _peers.removeWhere((_, p) => now - (p['lastSeen'] as int) > 6000);
    FlutterForegroundTask.sendDataToMain(jsonEncode({
      'roster': _peers.values.toList(),
    }));
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _ensureSockets(); // إعادة ربط أي سوكِت ماتت بعد انقطاع/عودة WiFi
    _sendBeacon();
    _sweepAndPublish();
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) {
      try {
        final obj = jsonDecode(data) as Map<String, dynamic>;
        if (obj['cmd'] == 'profile' && obj['profile'] is Map) {
          _profile = Map<String, dynamic>.from(obj['profile'] as Map);
          _sendBeacon();
        } else if (obj['cmd'] == 'endIncoming') {
          _endIncoming();
        }
      } catch (_) {}
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _discoverySocket?.close();
    _signalSocket?.close();
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  @override
  void onNotificationDismissed() {}
}
