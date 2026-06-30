import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// الملف الشخصي للمستخدم — يُحفظ محلياً في Hive ويُبثّ للأقران.
@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  /// مسار ملف صورة الأفاتار على الجهاز (إن وُجد).
  @HiveField(3)
  String? avatarPath;

  /// رقم الأفاتار الافتراضي عند عدم رفع صورة (assets/avatars/avatarN.png).
  @HiveField(4)
  int defaultAvatar;

  @HiveField(5)
  String? about;

  UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarPath,
    this.defaultAvatar = 0,
    this.about,
  });

  bool get hasCustomAvatar => avatarPath != null && avatarPath!.isNotEmpty;

  /// بصمة بسيطة للأفاتار تُستخدم لكشف تغيّر الصورة عند الأقران.
  String get avatarHash =>
      hasCustomAvatar ? avatarPath!.hashCode.toString() : 'def$defaultAvatar';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'defaultAvatar': defaultAvatar,
        'about': about,
        'avatarHash': avatarHash,
      };
}
