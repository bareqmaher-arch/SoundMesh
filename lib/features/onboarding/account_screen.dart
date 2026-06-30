import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/session_controller.dart';
import '../../core/settings_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_avatar.dart';
import '../../widgets/glass.dart';
import '../../widgets/gradient_button.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _avatarPath;
  int _defaultAvatar = 0;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  bool get _valid =>
      _name.text.trim().length >= 2 && _phone.text.trim().length >= 5;

  Future<void> _pickAvatar() async {
    final path = await ref.read(sessionControllerProvider.notifier).pickAvatar();
    if (path != null) setState(() => _avatarPath = path);
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    await ref.read(sessionControllerProvider.notifier).createAccount(
          name: _name.text,
          phone: _phone.text,
          avatarPath: _avatarPath,
          defaultAvatar: _defaultAvatar,
        );
    if (mounted) context.go('/gate');
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(appTextProvider);
    final p = context.palette;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(t.createAccount,
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
                Center(
                  child: Text(t.pickAvatar,
                      style: TextStyle(color: p.textDim, fontSize: 13)),
                ),
                const SizedBox(height: 16),
                _AvatarPalette(
                  selected: _avatarPath == null ? _defaultAvatar : -1,
                  onSelect: (i) => setState(() {
                    _defaultAvatar = i;
                    _avatarPath = null;
                  }),
                ),
                const SizedBox(height: 28),
                _label(t.yourName, p),
                TextField(
                  controller: _name,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(hintText: t.nameHint),
                ),
                const SizedBox(height: 18),
                _label(t.phone, p),
                TextField(
                  controller: _phone,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                  ],
                  decoration: InputDecoration(hintText: t.phoneHint),
                ),
                const SizedBox(height: 34),
                GradientButton(
                  label: t.continueLabel,
                  loading: _saving,
                  onPressed: _valid ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, AppPalette p) => Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(text,
              style:
                  TextStyle(color: p.text, fontWeight: FontWeight.w600)),
        ),
      );
}

class _AvatarPalette extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _AvatarPalette({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final isSel = i == selected;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSel ? AppColors.brand : null,
            ),
            child: AppAvatar(defaultAvatar: i, name: '★', size: 46),
          ),
        );
      }),
    );
  }
}
