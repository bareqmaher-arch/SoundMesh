import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'call_protocol.dart';

/// تدير إرسال إشارات الاتصال/الإلغاء للأقران (العزلة الرئيسية).
/// عرض الاتصال الوارد يتولّاه معالج الخلفية + شاشة الرنين المخصّصة.
class CallService {
  RawDatagramSocket? _sendSocket;

  Future<void> init() async {
    try {
      _sendSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      debugPrint('call send socket error: $e');
    }
  }

  /// بدء اتصال (رنين) نحو قائمة أقران عبر منفذ الإشارات.
  String startCall({
    required String fromId,
    required String fromName,
    required int fromDefaultAvatar,
    required bool group,
    required List<String> targetAddresses,
  }) {
    final callId = const Uuid().v4();
    final signal = CallSignal(
      type: CallSignal.typeCall,
      callId: callId,
      fromId: fromId,
      fromName: fromName,
      fromDefaultAvatar: fromDefaultAvatar,
      group: group,
    ).encode();
    _sendTo(signal, targetAddresses);
    return callId;
  }

  /// إيقاظ صامت للأقران (بثّ مباشر بلا رنين).
  void sendWake({
    required String fromId,
    required String fromName,
    required List<String> targetAddresses,
  }) {
    final signal = CallSignal(
      type: CallSignal.typeWake,
      callId: 'wake',
      fromId: fromId,
      fromName: fromName,
    ).encode();
    _sendTo(signal, targetAddresses);
  }

  /// إلغاء/إنهاء اتصال جارٍ عند الأقران.
  void cancelCall({
    required String callId,
    required String fromId,
    required List<String> targetAddresses,
  }) {
    final signal = CallSignal(
      type: CallSignal.typeCancel,
      callId: callId,
      fromId: fromId,
      fromName: '',
    ).encode();
    _sendTo(signal, targetAddresses);
  }

  void _sendTo(List<int> bytes, List<String> addresses) {
    final socket = _sendSocket;
    if (socket == null) {
      debugPrint('TW: مقبس الإرسال غير مهيّأ');
      return;
    }
    debugPrint('TW: إرسال إشارة اتصال إلى ${addresses.join(", ")} '
        'على المنفذ ${CallSignal.signalingPort}');
    for (final addr in addresses) {
      try {
        socket.send(bytes, InternetAddress(addr), CallSignal.signalingPort);
      } catch (e) {
        debugPrint('TW: خطأ إرسال الإشارة: $e');
      }
    }
  }

  void dispose() {
    _sendSocket?.close();
  }
}
