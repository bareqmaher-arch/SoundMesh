import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:taki_waki/core/network/protocol/packet.dart';

void main() {
  group('AudioPacket', () {
    test('encode ثم decode يحافظ على البيانات', () {
      final pcm = Uint8List.fromList(List.generate(640, (i) => i % 256));
      final packet = AudioPacket(
        senderId: 'user-1234',
        sequence: 42,
        timestampMs: 1700000000000,
        pcm: pcm,
      );

      final encoded = packet.encode();
      final decoded = AudioPacket.decode(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.senderId, 'user-1234');
      expect(decoded.sequence, 42);
      expect(decoded.timestampMs, 1700000000000);
      expect(decoded.pcm.length, 640);
      expect(decoded.pcm[10], pcm[10]);
    });

    test('decode يرفض الحِزَم غير الصوتية', () {
      final control = ControlPacket.leave('abc');
      expect(AudioPacket.decode(control), isNull);
    });
  });

  group('ControlPacket', () {
    test('beacon يحوي الحقول الأساسية', () {
      final data = ControlPacket.beacon(
        {'id': 'x', 'name': 'علي', 'phone': '0770', 'avatarHash': 'def0'},
        45455,
      );
      final map = ControlPacket.tryDecode(data);
      expect(map, isNotNull);
      expect(map!['t'], PacketType.beacon);
      expect(map['name'], 'علي');
      expect(map['tcpPort'], 45455);
    });
  });
}
