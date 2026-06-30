/// يمثّل مستخدماً آخر مكتشَفاً على الشبكة المحلية.
class Peer {
  final String id;
  String name;
  String phone;
  String avatarHash;
  int defaultAvatar;
  String address; // عنوان IP
  int tcpPort;
  DateTime lastSeen;

  /// هل يتحدث الآن (لتأثير التوهّج/الموجة في الواجهة).
  bool speaking;

  /// مسار صورة الأفاتار المخصّصة المستلمة من هذا الـ peer (إن وُجدت).
  String? avatarPath;

  Peer({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarHash,
    required this.defaultAvatar,
    required this.address,
    required this.tcpPort,
    required this.lastSeen,
    this.speaking = false,
    this.avatarPath,
  });

  bool get isOnline =>
      DateTime.now().difference(lastSeen) < const Duration(seconds: 6);

  factory Peer.fromBeacon(Map<String, dynamic> json, String address) => Peer(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'مستخدم',
        phone: json['phone'] as String? ?? '',
        avatarHash: json['avatarHash'] as String? ?? 'def0',
        defaultAvatar: (json['defaultAvatar'] as int?) ?? 0,
        address: address,
        tcpPort: (json['tcpPort'] as int?) ?? 45455,
        lastSeen: DateTime.now(),
      );
}
