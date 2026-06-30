import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session_controller.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/glass.dart';
import '../../widgets/gradient_button.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _about;
  String? _avatarPath;
  int _defaultAvatar = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(sessionControllerProvider).profile!;
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone);
    _about = TextEditingController(text: p.about ?? '');
    _avatarPath = p.avatarPath;
    _defaultAvatar = p.defaultAvatar;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final path = await ref.read(sessionControllerProvider.notifier).pickAvatar();
    if (path != null) setState(() => _avatarPath = path);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(sessionControllerProvider.notifier).updateAccount(
          name: _name.text,
          phone: _phone.text,
          avatarPath: _avatarPath,
          defaultAvatar: _defaultAvatar,
          about: _about.text,
        );
    if (mounted) {
      setState(() => _saving = false);
      final t = ref.read(appTextProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.savedChanges)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appTextProvider);
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(t.profile)),
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 8, 26, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.brand),
                          child: Hero(
                            tag: 'me-avatar',
                            child: AppAvatar(
                              imagePath: _avatarPath,
                              defaultAvatar: _defaultAvatar,
                              name: _name.text,
                              size: 116,
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          end: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                gradient: AppColors.brand,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final sel = _avatarPath == null && i == _defaultAvatar;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _defaultAvatar = i;
                        _avatarPath = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: sel ? AppColors.brand : null,
                        ),
                        child: AppAvatar(defaultAvatar: i, name: '★', size: 42),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                _field(t.yourName, _name, p),
                const SizedBox(height: 16),
                _field(t.phone, _phone, p, keyboard: TextInputType.phone),
                const SizedBox(height: 16),
                _field(t.aboutYou, _about, p, maxLines: 3),
                const SizedBox(height: 32),
                GradientButton(
                    label: t.save, loading: _saving, onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, AppPalette p,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
          child: Text(label,
              style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
        ),
        TextField(
          controller: c,
          keyboardType: keyboard,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }
}
