import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';

/// مخزن بسيط في الذاكرة لسجلّ الرسائل + حفظ ملفات الصور المستلمة.
class MessageStore {
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void add(ChatMessage message) => _messages.add(message);

  /// يحفظ بايتات صورة مستلمة في ملف ويعيد مساره.
  Future<String> saveIncomingImage(Uint8List bytes, String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/img_$id.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// يحفظ صورة أفاتار peer (يعيد الكتابة عند تغيّر البصمة) ويعيد المسار.
  Future<String> savePeerAvatar(
      Uint8List bytes, String peerId, String hash) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeHash = hash.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final path = '${dir.path}/peer_${peerId}_$safeHash.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
