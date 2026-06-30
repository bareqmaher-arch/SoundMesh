import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';

/// يحفظ ويحمّل الملف الشخصي محلياً (Hive) ويدير ملف الأفاتار.
class ProfileRepository {
  static const String boxName = 'profile_box';
  static const String key = 'me';

  late Box<UserProfile> _box;
  final ImagePicker _picker = ImagePicker();

  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    _box = await Hive.openBox<UserProfile>(boxName);
  }

  UserProfile? get current => _box.get(key);
  bool get hasProfile => current != null;

  Future<UserProfile> create({
    required String name,
    required String phone,
    String? avatarPath,
    int defaultAvatar = 0,
  }) async {
    final profile = UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      avatarPath: avatarPath,
      defaultAvatar: defaultAvatar,
    );
    await _box.put(key, profile);
    return profile;
  }

  Future<UserProfile> update({
    String? name,
    String? phone,
    String? avatarPath,
    int? defaultAvatar,
    String? about,
  }) async {
    final p = current!;
    if (name != null) p.name = name.trim();
    if (phone != null) p.phone = phone.trim();
    if (avatarPath != null) p.avatarPath = avatarPath;
    if (defaultAvatar != null) p.defaultAvatar = defaultAvatar;
    if (about != null) p.about = about;
    await p.save();
    return p;
  }

  /// اختيار صورة من المعرض وحفظ نسخة دائمة، وإرجاع المسار.
  Future<String?> pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 720,
      imageQuality: 85,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${dir.path}/$fileName');
    return saved.path;
  }
}
