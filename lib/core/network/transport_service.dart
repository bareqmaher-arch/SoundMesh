import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../models/chat_message.dart';
import 'protocol/packet.dart';

/// مسؤولة عن:
///  - استقبال/إرسال إطارات الصوت الحيّة عبر UDP unicast.
///  - استقبال/إرسال الرسائل والصور عبر TCP (موثوق).
class TransportService {
  static const int audioPort = 45456;
  static const int tcpPort = 45455;

  RawDatagramSocket? _audioSocket;
  ServerSocket? _tcpServer;

  final _audioController = StreamController<AudioPacket>.broadcast();
  Stream<AudioPacket> get incomingAudio => _audioController.stream;

  final _messageController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get incomingMessages => _messageController.stream;

  String _selfId = '';
  String _selfName = '';

  Future<void> start({required String selfId, required String selfName}) async {
    _selfId = selfId;
    _selfName = selfName;

    _audioSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      audioPort,
      reuseAddress: true,
    );
    _audioSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = _audioSocket!.receive();
      if (dg == null) return;
      final packet = AudioPacket.decode(dg.data);
      if (packet != null && packet.senderId != _selfId) {
        _audioController.add(packet);
      }
    });

    _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort,
        shared: true);
    _tcpServer!.listen(_handleTcpClient);
  }

  void updateSelf({String? name}) {
    if (name != null) _selfName = name;
  }

  // ---------------- الصوت (UDP unicast) ----------------

  void sendAudio({
    required Uint8List pcm,
    required int sequence,
    required List<({String address, int audioPort})> targets,
  }) {
    final socket = _audioSocket;
    if (socket == null) return;
    final packet = AudioPacket(
      senderId: _selfId,
      sequence: sequence,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      pcm: pcm,
    ).encode();
    for (final t in targets) {
      try {
        socket.send(packet, InternetAddress(t.address), t.audioPort);
      } catch (_) {}
    }
  }

  // ---------------- الرسائل/الصور (TCP) ----------------

  Future<void> _handleTcpClient(Socket socket) async {
    final buffer = BytesBuilder();
    try {
      await for (final chunk in socket) {
        buffer.add(chunk);
      }
    } catch (_) {
    } finally {
      _processIncoming(buffer.toBytes());
      socket.destroy();
    }
  }

  void _processIncoming(Uint8List bytes) {
    if (bytes.length < 4) return;
    final data = ByteData.view(bytes.buffer, bytes.offsetInBytes);
    final headerLen = data.getUint32(0, Endian.little);
    if (bytes.length < 4 + headerLen) return;
    final headerJson = utf8.decode(bytes.sublist(4, 4 + headerLen));
    final header = jsonDecode(headerJson) as Map<String, dynamic>;
    final body = Uint8List.sublistView(bytes, 4 + headerLen);

    final kind = header['kind'] as String;
    final senderId = header['senderId'] as String;
    final senderName = header['senderName'] as String? ?? 'مستخدم';
    final id = header['id'] as String;

    if (kind == 'text') {
      _messageController.add(ChatMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        kind: MessageKind.text,
        text: header['text'] as String?,
        time: DateTime.now(),
        isMine: false,
      ));
    } else if (kind == 'image') {
      // الصورة محفوظة لاحقاً بواسطة المستدعي عبر onImageBytes.
      onImageBytes?.call(id, senderId, senderName, body);
    } else if (kind == 'avatar') {
      // صورة الأفاتار الشخصية للمرسِل.
      final hash = header['avatarHash'] as String? ?? '';
      onAvatarBytes?.call(senderId, hash, body);
    }
  }

  /// callback يحفظ بايتات الصورة على القرص ويعيد ChatMessage.
  void Function(String id, String senderId, String senderName, Uint8List bytes)?
      onImageBytes;

  /// callback عند استلام صورة أفاتار من peer.
  void Function(String peerId, String avatarHash, Uint8List bytes)?
      onAvatarBytes;

  void emitIncomingMessage(ChatMessage message) =>
      _messageController.add(message);

  Future<void> sendText(
    String text,
    String messageId,
    List<({String address, int tcpPort})> targets,
  ) async {
    final header = utf8.encode(jsonEncode({
      'kind': 'text',
      'id': messageId,
      'senderId': _selfId,
      'senderName': _selfName,
      'text': text,
    }));
    await _sendTcp(header, Uint8List(0), targets);
  }

  Future<void> sendImage(
    Uint8List imageBytes,
    String messageId,
    List<({String address, int tcpPort})> targets,
  ) async {
    final header = utf8.encode(jsonEncode({
      'kind': 'image',
      'id': messageId,
      'senderId': _selfId,
      'senderName': _selfName,
    }));
    await _sendTcp(header, imageBytes, targets);
  }

  Future<void> sendAvatar(
    Uint8List imageBytes,
    String avatarHash,
    List<({String address, int tcpPort})> targets,
  ) async {
    final header = utf8.encode(jsonEncode({
      'kind': 'avatar',
      'id': 'avatar',
      'senderId': _selfId,
      'senderName': _selfName,
      'avatarHash': avatarHash,
    }));
    await _sendTcp(header, imageBytes, targets);
  }

  Future<void> _sendTcp(
    List<int> header,
    Uint8List body,
    List<({String address, int tcpPort})> targets,
  ) async {
    final frame = BytesBuilder();
    final lenBytes = ByteData(4)..setUint32(0, header.length, Endian.little);
    frame.add(lenBytes.buffer.asUint8List());
    frame.add(header);
    frame.add(body);
    final bytes = frame.toBytes();

    for (final t in targets) {
      try {
        final socket = await Socket.connect(t.address, t.tcpPort,
            timeout: const Duration(seconds: 4));
        socket.add(bytes);
        await socket.flush();
        await socket.close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    _audioSocket?.close();
    _audioSocket = null;
    await _tcpServer?.close();
    _tcpServer = null;
  }

  void dispose() {
    stop();
    _audioController.close();
    _messageController.close();
  }
}
