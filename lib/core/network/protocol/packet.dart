import 'dart:convert';
import 'dart:typed_data';

/// منافذ وعناوين الاكتشاف المشتركة بين العزلة الرئيسية وعزلة الخلفية.
class DiscoveryPorts {
  static const String multicastGroup = '239.7.7.7';
  static const int discoveryPort = 45454;
}

/// أنواع الحزم المتبادلة عبر الشبكة المحلية.
class PacketType {
  static const int beacon = 1; // إشارة حضور (UDP multicast)
  static const int audio = 2; // إطار صوت حي (UDP unicast)
  static const int leave = 3; // مغادرة صريحة (UDP multicast)
}

/// رأس ثنائي ثابت الطول لحِزَم الصوت + الحمولة (PCM16).
///
/// التخطيط (Little Endian):
///   [0]      type            (uint8)
///   [1..16]  senderId (16B)   نصّ UTF8 مبطّن بأصفار
///   [17..20] sequence         (uint32)
///   [21..28] timestampMs      (uint64)
///   [29..]   payload (PCM16)
class AudioPacket {
  static const int headerSize = 29;
  static const int idLength = 16;

  final String senderId;
  final int sequence;
  final int timestampMs;
  final Uint8List pcm;

  AudioPacket({
    required this.senderId,
    required this.sequence,
    required this.timestampMs,
    required this.pcm,
  });

  Uint8List encode() {
    final buffer = Uint8List(headerSize + pcm.length);
    final data = ByteData.view(buffer.buffer);
    data.setUint8(0, PacketType.audio);

    final idBytes = utf8.encode(senderId);
    for (int i = 0; i < idLength; i++) {
      buffer[1 + i] = i < idBytes.length ? idBytes[i] : 0;
    }
    data.setUint32(17, sequence & 0xFFFFFFFF, Endian.little);
    data.setUint64(21, timestampMs, Endian.little);
    buffer.setRange(headerSize, headerSize + pcm.length, pcm);
    return buffer;
  }

  static AudioPacket? decode(Uint8List buffer) {
    if (buffer.length < headerSize) return null;
    final data = ByteData.view(buffer.buffer, buffer.offsetInBytes);
    if (data.getUint8(0) != PacketType.audio) return null;

    final idBytes = <int>[];
    for (int i = 0; i < idLength; i++) {
      final b = buffer[1 + i];
      if (b == 0) break;
      idBytes.add(b);
    }
    final senderId = utf8.decode(idBytes);
    final sequence = data.getUint32(17, Endian.little);
    final timestampMs = data.getUint64(21, Endian.little);
    final pcm = Uint8List.sublistView(buffer, headerSize);
    return AudioPacket(
      senderId: senderId,
      sequence: sequence,
      timestampMs: timestampMs,
      pcm: pcm,
    );
  }
}

/// حِزَم الاكتشاف والمغادرة تُرسل كـ JSON-over-UDP (حجمها صغير).
class ControlPacket {
  static Uint8List beacon(Map<String, dynamic> profile, int tcpPort) {
    final map = {
      't': PacketType.beacon,
      'tcpPort': tcpPort,
      ...profile,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(map)));
  }

  static Uint8List leave(String id) {
    return Uint8List.fromList(
        utf8.encode(jsonEncode({'t': PacketType.leave, 'id': id})));
  }

  static Map<String, dynamic>? tryDecode(Uint8List buffer) {
    try {
      // حِزَم الصوت تبدأ بالبايت 2؛ تجاهلها هنا.
      if (buffer.isNotEmpty && buffer[0] == PacketType.audio) return null;
      final obj = jsonDecode(utf8.decode(buffer));
      if (obj is Map<String, dynamic>) return obj;
    } catch (_) {}
    return null;
  }
}
