enum MessageKind { text, image }

/// رسالة نصية أو صورة متبادلة بين الأقران.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final MessageKind kind;

  /// نص الرسالة (للنوع text).
  final String? text;

  /// مسار الصورة المحلية بعد الاستلام/الإرسال (للنوع image).
  final String? imagePath;

  final DateTime time;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.kind,
    this.text,
    this.imagePath,
    required this.time,
    required this.isMine,
  });
}
