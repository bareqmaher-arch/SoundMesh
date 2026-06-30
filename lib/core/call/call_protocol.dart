import 'dart:convert';
import 'dart:typed_data';

/// إشارات الاتصال تُرسل كـ JSON عبر UDP على منفذ مستقلّ مخصّص للإشارات،
/// كي يستمع لها معالج الخلفية (TaskHandler) حتى عند إغلاق واجهة التطبيق.
class CallSignal {
  static const int signalingPort = 45457;

  static const String typeCall = 'call'; // بدء اتصال (رنين)
  static const String typeCancel = 'cancel'; // إلغاء/إنهاء من الطرف الآخر
  static const String typeAccept = 'accept'; // قبول
  static const String typeDecline = 'decline'; // رفض
  static const String typeWake = 'wake'; // إيقاظ صامت للبثّ المباشر (بلا رنين)

  final String type;
  final String callId;
  final String fromId;
  final String fromName;
  final int fromDefaultAvatar;
  final String fromAddress; // عنوان المتصل (لإرسال الردّ)
  final bool group; // اتصال جماعي أم فردي

  CallSignal({
    required this.type,
    required this.callId,
    required this.fromId,
    required this.fromName,
    this.fromDefaultAvatar = 0,
    this.fromAddress = '',
    this.group = true,
  });

  Uint8List encode() => Uint8List.fromList(utf8.encode(jsonEncode({
        'sig': type,
        'callId': callId,
        'fromId': fromId,
        'fromName': fromName,
        'av': fromDefaultAvatar,
        'addr': fromAddress,
        'group': group,
      })));

  static CallSignal? decode(Uint8List bytes, {String? senderAddress}) {
    try {
      final obj = jsonDecode(utf8.decode(bytes));
      if (obj is! Map<String, dynamic> || obj['sig'] == null) return null;
      return CallSignal(
        type: obj['sig'] as String,
        callId: obj['callId'] as String? ?? '',
        fromId: obj['fromId'] as String? ?? '',
        fromName: obj['fromName'] as String? ?? 'مستخدم',
        fromDefaultAvatar: (obj['av'] as int?) ?? 0,
        fromAddress: (obj['addr'] as String?)?.isNotEmpty == true
            ? obj['addr'] as String
            : (senderAddress ?? ''),
        group: obj['group'] as bool? ?? true,
      );
    } catch (_) {
      return null;
    }
  }
}
